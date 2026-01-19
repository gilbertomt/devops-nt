# Stage 1: Build
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY ["app/devops-nt-app/devops-nt-app.csproj", "./"]
RUN dotnet restore "devops-nt-app.csproj"
COPY ["app/devops-nt-app/", "./"]
RUN dotnet publish -c Release -o /app/publish "devops-nt-app.csproj"

# Stage 2: Runtime
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app
RUN groupadd -r appuser && useradd -r -g appuser appuser
USER appuser
COPY --from=build /app/publish .
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:8080/health || exit 1
ENV ASPNETCORE_URLS=http://+:8080
ENTRYPOINT ["dotnet", "devops-nt-app.dll"]