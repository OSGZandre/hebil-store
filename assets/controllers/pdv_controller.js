import { Controller } from '@hotwired/stimulus';

/**
 * PDV — operação por teclado.
 *
 * Filosofia: o operador deve usar o mouse **só** em casos excepcionais.
 * O caret nasce no campo de código de barras e volta para lá toda vez que
 * possível, para o leitor poder bipar o próximo item sem nenhuma ação.
 *
 * Atalhos:
 *   F2  → focar busca de produto
 *   F4  → focar valor recebido (pagamento)
 *   F8  → finalizar venda
 *   Esc → voltar para o código de barras (resetar contexto)
 *   Enter no barcode → "Adicionar" (mesma ação do botão)
 *
 * O backend ainda não existe (Fase 4 do plano-implementacao.md). Este
 * controller só faz a interação visual: foca/desfoca, marca o método
 * selecionado e dispara confirmações. Quando a Fase 4 entrar, basta
 * substituir os `console.info` por chamadas fetch/Turbo.
 */
export default class extends Controller {
    static targets = ['barcode', 'search', 'addButton', 'paymentMethod', 'received', 'finalize'];

    connect() {
        this.focusBarcode();
    }

    /* ---------- atalhos globais (data-action="keydown@window->pdv#handleShortcut") ---------- */
    handleShortcut(event) {
        // Ignora se o usuário estiver digitando em uma <textarea> ou inputs de outras telas
        // (no PDV não há textareas, mas mantém a guarda para o futuro)
        const tag = event.target.tagName;
        const isTyping = tag === 'TEXTAREA';

        switch (event.key) {
            case 'F2':
                event.preventDefault();
                this.focusSearch();
                break;
            case 'F4':
                event.preventDefault();
                this.focusReceived();
                break;
            case 'F8':
                event.preventDefault();
                this.finalize();
                break;
            case 'Escape':
                if (!isTyping) event.preventDefault();
                this.focusBarcode();
                break;
        }
    }

    /* ---------- ações de campo ---------- */
    submitBarcode(event) {
        if (event && typeof event.preventDefault === 'function') event.preventDefault();

        const code = this.hasBarcodeTarget ? this.barcodeTarget.value.trim() : '';
        if (!code) {
            this.focusBarcode();
            return;
        }

        // TODO Fase 4: POST /pdv/itens { codigo: code } e renderizar nova linha.
        console.info('[pdv] adicionar item por código:', code);

        // Limpa e devolve o foco para o próximo bip — sem clicar em nada.
        this.barcodeTarget.value = '';
        this.focusBarcode();
    }

    selectPayment(event) {
        const clicked = event.currentTarget;
        this.paymentMethodTargets.forEach((btn) => {
            const active = btn === clicked;
            btn.classList.toggle('is-active', active);
            btn.setAttribute('aria-checked', active ? 'true' : 'false');
        });

        // Após escolher a forma, foco já vai para "valor recebido" se for dinheiro.
        if (clicked.dataset.method === 'dinheiro') {
            this.focusReceived();
        }
    }

    finalize(event) {
        if (event && typeof event.preventDefault === 'function') event.preventDefault();

        // TODO Fase 4: POST /pdv/finalizar e redirecionar para impressão / nova venda.
        console.info('[pdv] finalizar venda');
        this.focusBarcode();
    }

    /* ---------- helpers de foco ---------- */
    focusBarcode() {
        if (this.hasBarcodeTarget) {
            this.barcodeTarget.focus();
            this.barcodeTarget.select();
        }
    }

    focusSearch() {
        if (this.hasSearchTarget) {
            this.searchTarget.focus();
            this.searchTarget.select();
        }
    }

    focusReceived() {
        if (this.hasReceivedTarget) {
            this.receivedTarget.focus();
            this.receivedTarget.select();
        }
    }
}
