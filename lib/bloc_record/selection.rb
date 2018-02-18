require 'sqlite3'

module Selection
    def find(*ids)
        raise ArgumentError.new("all id's must be integers") unless ids.all? {|i| i.is_a?(Integer) }
        ids.map! {|i| i.abs }
        
        if ids.length == 1
            find_one(ids.first)
        else
            rows = connection.execute <<-SQL
                 SELECT #{columns.join ","} FROM #{table}
                 WHERE id IN (#{ids.join(",")});
             SQL
        
            rows_to_array(rows)
        end
    end
   
    def find_one(id)
        raise ArgumentError.new("id must be an integer") unless id.is_a?(Integer)
        id.abs!
        
        row = connection.get_first_row <<-SQL
            SELECT #{columns.join ","} FROM #{table}
            WHERE id = #{id};
        SQL
        
        init_object_from_row(row)
    end
    
    def find_by(attribute, value)
        # raise ArgumentError.new("attribute must be a string") unless attribute.is_a?(String)
        # raise ArgumentError.new("value must be a string or integer") unless value.is_a?(String) || unless value.is_a?(Integer)
            
        rows = connection.execute <<-SQL
            SELECT #{columns.join ","} FROM #{table}
            WHERE #{attribute} = #{BlocRecord::Utility.sql_strings(value)};
        SQL
        
        rows_to_array(rows)
    end
    
    def method_missing(m, *args, &block)
        if m.include?("find_by")
            i = m.indexOf("y_")
            m = m[i+2]
            find_by(m, args[0])
        else
            raise NameError.new("There is no such method")
        end
    end
    
    
    def find_each(search = {})
        start = search[:start]
        batch_size = search[:batch_size]
        rows = connection.execute <<-SQL
            SELECT #{columns.join ","} FROM #{table}
            WHERE id >= #{start} LIMIT #{batch_size};
        SQL
        
        yield(rows_to_arrays(rows))
    end
    
    def find_in_batches(search = {})
        start = search[:start]
        batch_size = search[:batch_size]
        rows = connection.execute <<-SQL
            SELECT #{columns.join ","} FROM #{table}
            ORDER BY id WHERE search 
            OFFSET #{start} LIMIT #{batch_size};
        SQL
        
        yield(rows_to_arrays(rows))
    end
   
    def take(num=1)
        raise ArgumentError.new("num must be an integer") unless num.is_a?(Integer)
        num.abs!
        
        if num > 1
            rows = connection.execute <<-SQL
                SELECT #{columns.join ","} FROM #{table}
                ORDER BY random()
                LIMIT #{num};
            SQL
            
            rows_to_array(rows)
        else
            take_one
        end
    end
    
    def take_one
        row = connection.get_first_row <<-SQL
            SELECT #{columns.join ","} FROM #{table}
            ORDER BY random()
            LIMIT 1;
        SQL
        
        init_object_from_row(row)
    end
   
    def first
        row = connection.get_first_row <<-SQL
            SELECT #{columns.join ","} FROM #{table}
            ORDER BY id ASC LIMIT 1;
        SQL
        
        init_object_from_row(row)
    end
    
    def last
        row = connection.get_first_row <<-SQL
            SELECT #{columns.join ","} FROM #{table}
            ORDER BY id DESC LIMIT 1;
        SQL
        
        init_object_from_row(row)
    end
    
    def all
        rows = connection.execute <<-SQL
            SELECT #{columns.join ","} FROM #{table};
        SQL
        
        rows_to_array(rows)
    end
 
   
    private
    def init_object_from_row(row)
        if row
            data = Hash[columns.zip(row)]
            new(data)
        end
    end
    
    def rows_to_array(rows)
        rows.map { |row| new(Hash[columns.zip(row)]) }
    end
end