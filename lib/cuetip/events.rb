module Cuetip
  module Events

    def _cuetip_events
      @_cuetip_events ||= {}
    end

    def on(event_name, &block)
      _cuetip_events[event_name.to_sym] ||= []
      _cuetip_events[event_name.to_sym] << block
    end

    def emit(event_name, *args)
      if events = self._cuetip_events[event_name.to_sym]
        events.each do |block|
          block.call(*args)
        end
      end

      if self.respond_to?(:superclass) && self.superclass.respond_to?(:_cuetip_events)
        self.superclass.emit(event_name, *args)
      end
    end

  end
end
