Rage.routes.draw do
  root to: ->(env) { [200, {}, "It works!"] }

  post "/clientes/:id/transacoes", to: "transactions#create"
  get "/clientes/:id/extrato", to: "bank_statements#show"
end
