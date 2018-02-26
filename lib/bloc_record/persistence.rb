 require 'sqlite3'
 require 'bloc_record/schema'
 
 module Persistence
     
    def self.included(base)
        base.extend(ClassMethods)
    end
    
    def save
        self.save! rescue false
    end
    
    def save!
        unless self.id
            self.id = self.class.create(BlocRecord::Utility.instance_variables_to_hash(self)).id
            BlocRecord::Utility.reload_obj(self)
            return true
        end
        
        fields = self.class.attributes.map { |col| "#{col}=#{BlocRecord::Utility.sql_strings(self.instance_variable_get("@#{col}"))}" }.join(",")
        
        self.class.connection.execute <<-SQL
            UPDATE #{self.class.table}
            SET #{fields}
            WHERE id = #{self.id};
        SQL
        
        true
    end

    def update_attribute(attribute, value)
        self.class.update(self.id, { attribute => value })
    end
   
    def update_attributes(updates)
        self.class.update(self.id, updates)
    end
 
   module ClassMethods
     def create(attrs)
       attrs = BlocRecord::Utility.convert_keys(attrs)
       attrs.delete "id"
       vals = attributes.map { |key| BlocRecord::Utility.sql_strings(attrs[key]) }
 
       connection.execute <<-SQL
         INSERT INTO #{table} (#{attributes.join ","})
         VALUES (#{vals.join ","});
       SQL
 
       data = Hash[attributes.zip attrs.values]
       data["id"] = connection.execute("SELECT last_insert_rowid();")[0][0]
       new(data)
     end
     
    def update(ids, updates)
        if ids.is_a?(Array) && updates.is_a?(Array)
            for i in 0..updates.count - 1 do
                update_once(ids[i], updates[i])
            end
        else
            update_once(ids, updates)
        end
        true
    end
     
    def update_once(ids, updates)
        # puts "ids = #{ids.class}"
        # puts "updates = #{updates.class}"
        updates = BlocRecord::Utility.convert_keys(updates)
        updates.delete "id"
        # puts " new updates = #{updates}"
        updates_array = updates.map { |key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}" }
        
        if ids.class == Fixnum
            where_clause = "WHERE id = #{ids};"
        elsif ids.class == Array
            where_clause = ids.empty? ? ";" : "WHERE id IN (#{ids.join(",")});"
        else
            where_clause = ";"
        end
        
        connection.execute <<-SQL
            UPDATE #{table}
            SET #{updates_array * ","}
            WHERE id = #{id};
            SET #{updates_array * ","} #{where_clause}
        SQL
        
        true
    end
    
    def update_all(updates)
        update(nil, updates)
    end
    
    def method_missing(m, *args, &block)
        m = m.to_s
        if m.include?("update")
            i = m.index("e_")
            m = m[i+2..-1].to_s
            update(:m, args[0])
        else
            raise ArgumentError.new("There is no such method")
        end
    end
   end
 end