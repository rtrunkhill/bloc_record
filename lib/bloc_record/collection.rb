module BlocRecord
    class Collection < Array
        def update_all(updates)
            ids = self.map(&:id)
            self.any? ? self.first.class.update(ids, updates) : false
        end
        #Person.where(first_name: 'John').take;
        def take(num=1)
            if self.any?
                took = []
                if num > 1
                    self.each do |i| 
                        took << self[i]
                    end
                else
                    took = self[0]
                end
                took
            else
                false
            end
        end
        
        #Person.where(first_name: 'John').where(last_name: 'Smith')
        def where(*args)
            self.any? ? self.first.where(args) : false
        end
        
        #Person.where.not(first_name: 'John')
        def not(*args)
            self.any? ? self.first.not(args) : false
        end
    
    end
end