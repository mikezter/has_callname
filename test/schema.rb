ActiveRecord::Schema.define(:version => 0) do  
  create_table :things, :force => true do |t| 
    t.string :name  
    t.string :callname
    t.string :something
    t.timestamps
  end  


end 
