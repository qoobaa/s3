# Copyright (c) 2008 Ryan Daigle

# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation files
# (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:

# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
# BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

module Stree
  module Roxy # :nodoc:all
    module Moxie
      # Set up this class to proxy on the given name
      def proxy(name, options = {}, &block)

        # Make sure args are OK
        original_method = method_defined?(name) ? instance_method(name) : nil
        raise "Cannot proxy an existing method, \"#{name}\", and also have a :to option.  Please use one or the other." if
          original_method and options[:to]

        # If we're proxying an existing method, we need to store
        # the original method and move it out of the way so
        # we can take over
        if original_method
          new_method = "proxied_#{name}"
          alias_method new_method, "#{name}"
          options[:to] = original_method
        end

        # Thanks to Jerry for this simplification of my original class_eval approach
        # http://ryandaigle.com/articles/2008/11/10/implement-ruby-proxy-objects-with-roxy/comments/8059#comment-8059
        if !original_method or original_method.arity == 0
          define_method name do
            @proxy_for ||= {}
            @proxy_for[name] ||= Proxy.new(self, options, nil, &block)
          end
        else
          define_method name do |*args|
            Proxy.new(self, options, args, &block)
          end
        end
      end
    end
  end
end
