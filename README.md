# 💸 Gastos App

Aplicativo Flutter de controle de gastos pessoais com **offline first**, interpretação de frases em português e sincronização com Google Sheets via Google Apps Script.

---

## ✅ Requisitos

- Flutter SDK `>=3.0.0`
- Dart `>=3.0.0`
- Android Studio ou VS Code com extensão Flutter

---

## 🚀 Como rodar

### 1. Clone e instale as dependências

```bash
git clone <seu-repositorio>
cd gastos_app
flutter pub get
```

### 2. Configure a URL do backend

Abra `lib/core/config/app_config.dart` e altere:

```dart
static const String backendUrl = 'https://script.google.com/macros/s/SEU_ID_AQUI/exec';
```

Substitua `SEU_ID_AQUI` pelo ID do seu Google Apps Script Web App.

### 3. Rode o app

```bash
flutter run
```

---

## 📋 Google Apps Script — Setup

1. Acesse [script.google.com](https://script.google.com) e crie um novo projeto
2. Cole o código abaixo:

```javascript
function doPost(e) {
  try {
    const data = JSON.parse(e.postData.contents);
    const sheet = SpreadsheetApp.openById('SEU_SHEET_ID').getActiveSheet();

    sheet.appendRow([
      data.dataHora,
      data.tipo,
      data.valor,
      data.pagamento,
      data.textoOriginal,
      new Date().toISOString()
    ]);

    return ContentService
      .createTextOutput(JSON.stringify({ ok: true, message: 'Gasto inserido com sucesso' }))
      .setMimeType(ContentService.MimeType.JSON);
  } catch (err) {
    return ContentService
      .createTextOutput(JSON.stringify({ ok: false, message: err.toString() }))
      .setMimeType(ContentService.MimeType.JSON);
  }
}
```

3. Vá em **Implantar > Nova implantação**
4. Tipo: **App da Web**
5. Executar como: **Eu**
6. Acesso: **Qualquer pessoa**
7. Copie a URL gerada e cole em `app_config.dart`

---

## 📱 Fluxo do app

```
HomeScreen → [+ Novo gasto] → NewEntryScreen
                                    ↓ (digita frase)
                              ConfirmationScreen
                                    ↓ (confirma)
                    Salva no Hive (status: pending)
                                    ↓
                    Tenta POST no backend
                    ├── Sucesso → status: synced
                    └── Falha  → status: failed
                                    ↓
                              HomeScreen (atualizada)
```

---

## 🔌 Testando offline

1. Desative o Wi-Fi/dados do dispositivo
2. Abra o app e registre um gasto normalmente
3. O gasto será salvo localmente com status **Pendente** (ícone âmbar)
4. Reative a internet
5. Na tela de Histórico, toque em **Reenviar** no item pendente

---

## 💥 Testando falha de sync

1. Em `app_config.dart`, coloque uma URL inválida:
   ```dart
   static const String backendUrl = 'https://url-invalida.exemplo.com';
   ```
2. Registre um gasto
3. O status aparecerá como **Falha** (ícone vermelho)
4. Corrija a URL e use o botão **Reenviar** no histórico

---

## 🏗️ Estrutura do projeto

```
lib/
├── core/           # Tema, rotas, constantes, utilitários
├── domain/         # Entidades, enums, contratos (sem dependências externas)
├── data/           # Models Hive, datasources, repositories, sync, parser
└── presentation/   # Telas, widgets, providers, notifiers
```

---

## 🗺️ Próximos passos

| Feature | Como fazer |
|---|---|
| **Entrada por voz** | Implemente `VoiceInputButton` com `speech_to_text` package |
| **Parser com IA** | Crie nova implementação de `PhraseParserService` chamando OpenAI/Gemini |
| **Sync automático em background** | Use `workmanager` + `SyncService.syncAllPending()` |
| **Gráficos** | Adicione `fl_chart` e consuma `expensesByCategoryProvider` |
| **Exportar CSV** | Use `csv` package + `share_plus` |
| **Notificações** | `flutter_local_notifications` para alertas de gastos |
| **Trocar backend** | Altere apenas `ExpenseRemoteDataSource` — nenhuma tela muda |
| **Autenticação** | Adicione auth no `AppConfig` e injete token no header HTTP |

---

## 🧪 Arquivos gerados pelo Hive

Os arquivos `.g.dart` já estão incluídos no projeto. Se precisar regenerar após alterar models:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```