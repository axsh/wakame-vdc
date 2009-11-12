
def public_crud obj
  public_name = obj.table_name.to_s # instances
  model = obj.to_s # Instances

list = eval(<<END )
  proc do
    #{public_name}_list = #{model}.all
    erb :"#{public_name}/index"
  end
END
  
get_instance = eval(<<END )
  proc do
    #{public_name}_list = #{model}.all
    erb :"#{public_name}/new"
  end
END

new_instance = eval(<<END )
  proc do
    #{public_name}_list = #{model}.all
    erb :"#{public_name}/new"
  end
END

update_instance = eval(<<END )
  proc do
    id = params[:id]
    @id = id
    erb :"#{public_name}/update"
  end
END

delelete_instance = eval(<<END )
  proc do
    erb :"#{public_name}/update"
    # #{model}.filter(:id=>id).delete
    # redirect "/#{public_name}"
  end
END

  get    "/#{public_name}.json"  ,&list 
  
  post   "/#{public_name}.json"  ,&new_instance
  
  get    %r{/#{public_name}/(\d+).json}  ,&get_instance
  put    %r{/#{public_name}/(\d+).json}  ,&update_instance
  delete %r{/#{public_name}/(\d+).json}  ,&delelete_instance
end
