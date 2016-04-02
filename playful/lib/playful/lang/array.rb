module Playful
  module Lang
    module  Array
      def pluck key
        map { |hash| hash[key] }
      end
    end
  end
end
