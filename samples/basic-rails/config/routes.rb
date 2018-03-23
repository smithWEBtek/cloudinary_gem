Basic::Application.routes.draw do
	root :to => 'demo#index'
	
	get 'resources', to: 'demo#resources_index'
	get 'pdfs', to: 'demo#pdfs_index'
end
