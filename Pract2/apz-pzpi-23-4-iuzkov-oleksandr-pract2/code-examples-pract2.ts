
// ============================================================
// 1. Реєстрація розширення та команди (Extension API)
// ============================================================

import * as vscode from 'vscode';

export function activate(context: vscode.ExtensionContext) {
    // Реєстрація команди у реєстрі команд VS Code
    const disposable = vscode.commands.registerCommand(
        'myExtension.helloWorld',
        () => {
            vscode.window.showInformationMessage('Hello from extension!');
        }
    );

    // Підписка на подію відкриття текстового документа
    const onOpenDoc = vscode.workspace.onDidOpenTextDocument(doc => {
        console.log('Opened:', doc.fileName, '| Language:', doc.languageId);
    });

    // Реєстрація провайдера автодоповнення для TypeScript
    const completionProvider = vscode.languages.registerCompletionItemProvider(
        'typescript',
        {
            provideCompletionItems(document, position) {
                const item = new vscode.CompletionItem('console.log');
                item.kind = vscode.CompletionItemKind.Snippet;
                item.insertText = new vscode.SnippetString('console.log($1);');
                item.documentation = 'Виводить повідомлення у консоль';
                return [item];
            }
        },
        '.'  // Тригерний символ
    );

    context.subscriptions.push(disposable, onOpenDoc, completionProvider);
}

export function deactivate() {}


// ============================================================
// 2. Language Server Protocol (LSP) — мовний сервер
// ============================================================

import {
    createConnection,
    TextDocuments,
    Diagnostic,
    DiagnosticSeverity,
    CompletionItem,
    CompletionItemKind,
    TextDocumentPositionParams,
    InitializeResult,
    ProposedFeatures
} from 'vscode-languageserver/node';

import { TextDocument } from 'vscode-languageserver-textdocument';

// Створення з'єднання між редактором і мовним сервером
const connection = createConnection(ProposedFeatures.all);
const documents = new TextDocuments(TextDocument);

// Ініціалізація: оголошення підтримуваних можливостей
connection.onInitialize((): InitializeResult => {
    return {
        capabilities: {
            completionProvider: {
                resolveProvider: true,
                triggerCharacters: ['.', ':']
            },
            hoverProvider: true,
            diagnosticProvider: {
                interFileDependencies: false,
                workspaceDiagnostics: false
            }
        }
    };
});

// Обробник запитів автодоповнення
connection.onCompletion((params: TextDocumentPositionParams): CompletionItem[] => {
    return [
        {
            label: 'TypeScript',
            kind: CompletionItemKind.Text,
            data: 1
        },
        {
            label: 'JavaScript',
            kind: CompletionItemKind.Text,
            data: 2
        },
    ];
});

// Обробник уточнення елемента автодоповнення
connection.onCompletionResolve((item: CompletionItem): CompletionItem => {
    if (item.data === 1) {
        item.detail = 'TypeScript details';
        item.documentation = 'Статично типізована мова програмування';
    }
    return item;
});

// Валідація документа — генерація діагностичних повідомлень
async function validateDocument(doc: TextDocument): Promise<void> {
    const diagnostics: Diagnostic[] = [];
    const text = doc.getText();

    // Приклад: попередження при використанні var
    const varPattern = /\bvar\b/g;
    let match;
    while ((match = varPattern.exec(text)) !== null) {
        diagnostics.push({
            severity: DiagnosticSeverity.Warning,
            range: {
                start: doc.positionAt(match.index),
                end: doc.positionAt(match.index + match[0].length)
            },
            message: 'Використовуйте const або let замість var',
            source: 'myLanguageServer'
        });
    }

    connection.sendDiagnostics({ uri: doc.uri, diagnostics });
}

// Реакція на зміну документа
documents.onDidChangeContent(change => {
    validateDocument(change.document);
});

documents.listen(connection);
connection.listen();