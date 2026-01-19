var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.MapGet("/", () =>
    "DevOps NT APP | Aplicação ASP.NET Core em execução no EKS AWS.\n" +
    "Cluster provisionado com Terraform.\n" +
    "Autor: Gilberto Teodoro."
);

app.MapGet("/health", () => Results.Ok(new
{
    status = "healthy",
    service = "devops-nt-app"
}));

app.Run();
