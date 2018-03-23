Basic::Application.routes.draw do
	root :to => 'demo#index'
	
	get 'resources', to: 'demo#resources_index'
end
