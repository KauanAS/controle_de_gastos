# Puxa uma imagem que já vem com o Flutter pronto e configurado
FROM ghcr.io/cirruslabs/flutter:stable

# Cria uma pasta de trabalho lá dentro do container
WORKDIR /app

# Copia todo o seu projeto da sua máquina para dentro do container
COPY . /app/

# Comando para não deixar o container desligar sozinho
CMD ["tail", "-f", "/dev/null"]