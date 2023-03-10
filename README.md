# Cuetip

Cuetip is a fast & reliable job queueing engine for applications that already use ActiveRecord. In its most simple form, workers will poll the database for jobs and execute them.

## Installation

```ruby
gem 'cuetip', '~> 1.0'
```

Once you have installed the gem, you'll need to copy over the migrations required to create the tables Cuetip needs to work.

```
$ bundle exec rake cuetip:install:migrations
$ bundle exec rake db:migrate
```

## Configuration

There is some configuration which is required. In a Rails application, in: `config/initializers/cuetip.rb`.

```ruby
Cuetip.configure do |config|

  # The interval between polling
  config.polling_interval = 10.seconds

  # Set a logger where all Cuetip related log messages will be sent to. By default, they will go to STDOUT.
  config.logger = Klogger.new(:cuetip, destination: Rails.root.join('log', 'cuetip.log'))

  # Configure a block to execute whenever an exception is encountered in a job. You might
  # use this for reporting to an exception reporting service. It is optional.
  config.on(:exception) do |exception, job|
    Raven.capture_exception(exception, :extra => {:job => job.id})
  end

end
```

and in: `config/cuetip.rb`

```
require_relative 'environment'
```

## Jobs

To create a job to be executed by Cuetip, you need to make a class which inherits from `Cuetip::Job`. This class should implement (at a minimum) a `perform` method that will be executed when the job is queued. For example:

```ruby
class ExampleJob < Cuetip::Job

  def perform
    # Do some long running work here.
  end

end
```

If you're working in a Rails application, you can place your jobs in a `app/jobs` directory.

When you want to queue a job for execution you can do so as follows. When you call `queue` it will return a `Cuetip::QueuedJob` object which is an ActiveRecord model for the backend job that has been queued.

```ruby
job = ExampleJob.queue
job.id          # => The ID of the newly queued job.
job.status      # => Returns the status of the job
job.exception   # => If the job raised an exception, the exeception details will be available here.
```

### Parameters

You can pass parameters to your job when queueing it. These must be something that can be serialised into JSON for persistence into the database. To access parameters within your job you can call the `params` method which will return a `Hashie::Mash` which allows you to access them in a flexible manner (i.e. `params[:key]` or `params.key`).

To send these parameters to the job, you can do so by passing a hash to the `queue` method as so:

```ruby
ExampleJob.queue(:example => 'Some Example Param')
```

### Errors & Exception

Any exception that occurs while your job is being processed will be logged with the job and can be looked up at any point in the future.

### Retrying failed jobs

By default, jobs will not retry on exception. You can configure how many times to retry a job on failure by setting the `retry_count` when queueing the job.

```ruby
ExampleJob.queue do |job|
  job.retry_count = 5                 # The number of times this job should be tried before giving up
  job.retry_interval = 30.seconds     # The length of time between retries
end
```

If a job is queued with retries enabled and you want to abort the current and any future executions, you can raise an error. The job status will be set to `Aborted`.

```ruby
def perform
  raise Cuetip::AbortJob, "The reason for aborting the job"
end
```

### Queues

By default, there is a single queue that will process jobs. Unless otherwise told, all jobs will happen on the the `default` queue. You can choose a queue to run a job on either by specifying it when queued or on the job itself.

```ruby
# Define the queue every execution of a specific job
class ExampleJob < Cuetip::Job
  self.queue = 'otherqueue'
end

# Define the queue for a single queueing of a job
ExampleJob.queue do |job|
  job.queue = 'otherqueue'
end
```

### Delays

If you wish to execute a job later in time, you can configure this when queueing the job. The job will be removed from the queue automatically at this time and

```ruby
ExampleJob.queue do |job|
  job.run_after = 10.minutes.from_now
end
```

### Maximum Execution Time

You can set a maximum time that a job will be executed for before it is terminated by the worker. You can do this on job class itself or set when the job is queued.

```ruby
# Define the maximum execution time for every execution of a job type
class ExampleJob < Cuetip::Job
  self.maximum_execution_time = 1.hour
end

# Define the maximum execution time for a specific job
ExampleJob.queue do |job|
  job.maximum_execution_time = 12.minutes
end
```

### TTL

You can specify a TTL on jobs which means that they won't be executed if they aren't run within a certain period from when they were queued.

```ruby
# Define the TTL for every execution of a job type
class ExampleJob < Cuetip::Job
  self.ttl = 10.minutes
end

# Define the TTL for a specific job
ExampleJob.queue do |job|
  job.ttl = 10.seconds
end
```

## Workers

To run a Cuetip worker you can use the `cuptip` executable that is provided. You should pass it a configuration file that will be required when it starts. This will need to require your application's environment.

```
$ bundle exec cuetip -c config/cuetip.rb
```

You can run as many workers as you wish however the more that you run the more polling queries will be sent to your database.

## Testing

In order to unit test a `Cuetip::Job`'s instance methods (such as `#perform`), it first needs to be instanciated passing in an instance of `Cuetip::Models::Job`. This is best done with a tesing double:

### RSpec

```ruby
subject(:job) { JobClass.new(job_model) }

let(:job_model) { instance_double('Cuetip::Models::Job') }

describe '#perform' do
  it 'does something' do
    job.perform

    # add expectaions here
  end
end
```
