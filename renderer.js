const input = document.getElementById('q');
const mirror = document.getElementById('mirror');

const commandsList = ['google', 'wiki', 'yt', 'duck', 'open', 'file', 'mark'];

let history = [];
let historyIndex = -1;

function measure() {
    mirror.textContent = (input.value || '') + ' ';
    return {
        width: Math.ceil(mirror.getBoundingClientRect().width),
        height: Math.ceil(mirror.getBoundingClientRect().height),
    };
}

let rafId = null;
function requestResize() {
    if (rafId) cancelAnimationFrame(rafId);
    rafId = requestAnimationFrame(() => {
        const { width, height } = measure();
        input.style.width = width + 'px';
        input.style.height = height + 'px';
        window.native?.setWidth?.(width);
    });
}
function isMathExpression(str) {
    return /^[0-9+\-*/().,^%\s]+$/.test(str);
}

function calc(exprRaw) {
    const expr = exprRaw.replace(/,/g, '.').replace(/\^/g, '**');
    if (!isMathExpression(expr)) throw new Error('Invalid');
    return new Function(`"use strict"; return (${expr});`)();
}

const commands = {
    google(q) {
        const url = `https://www.google.com/search?q=${encodeURIComponent(q)}`;
        window.native?.openExternal?.(url);
    },
    wiki(q) {
        const url = `https://it.wikipedia.org/w/index.php?search=${encodeURIComponent(q)}`;
        window.native?.openExternal?.(url);
    },
    yt(q) {
        const url = `https://www.youtube.com/results?search_query=${encodeURIComponent(q)}`;
        window.native?.openExternal?.(url);
    },
    duck(q) {
        const url = `https://duckduckgo.com/?q=${encodeURIComponent(q)}`;
        window.native?.openExternal?.(url);
    },
    open(u) {
        const url = u.startsWith('http') ? u : `https://${u}`;
        window.native?.openExternal?.(url);
    },

    mark(p) {
        const filePath = p.trim();
        if (filePath.endsWith('.md')) {
            window.native?.openWithMark(filePath);
        } else {
            const prev = input.value;
            input.value = 'Non è un file .md valido';
            requestResize();
            setTimeout(() => { input.value = prev; requestResize(); }, 800);
        }
    },

    async file(q) {
        const term = String(q || '').trim();
        if (!term) return;
        try {
            const results = await window.native?.searchFiles?.(term);
            if (Array.isArray(results) && results.length) {
                window.native?.revealInFolder?.(results[0]);
            } else {
                const prev = input.value;
                input.value = 'Nessun file trovato';
                requestResize();
                setTimeout(() => { input.value = prev; requestResize(); }, 800);
            }
        } catch (e) {
            const prev = input.value;
            input.value = 'Errore ricerca file';
            requestResize();
            setTimeout(() => { input.value = prev; requestResize(); }, 800);
        }
    },
};

function executeLine(text) {
    const t = text.trim().toLowerCase();

    if (t === 'exit') {
        window.native?.exitApp();
        return { type: 'exit' };
    }

    const m = t.match(/^\/([a-zA-Z]+)(?:\s+(.*))?$/);
    if (m) {
        const cmd = m[1].toLowerCase();
        const arg = m[2] || '';
        if (typeof commands[cmd] === 'function') {
            commands[cmd](arg);
            return { type: 'command' };
        }
        return { type: 'noop' };
    }

    if (isMathExpression(t)) {
        try {
            const result = calc(t);
            return { type: 'math', result: String(result) };
        } catch { }
    }

    return { type: 'noop' };
}



input.addEventListener('beforeinput', (e) => {
    if (e.inputType === 'insertLineBreak') e.preventDefault();
});
input.addEventListener('input', () => {
    if (input.value.includes('\n')) {
        input.value = input.value.replace(/\s*\n+\s*/g, ' ');
    }
    requestResize();
});

input.addEventListener('keydown', (e) => {
    if (e.key === 'Enter' || e.key === 'NumpadEnter') {
        e.preventDefault();

        const currentValue = input.value;
        const res = executeLine(currentValue);

        if (currentValue.trim() !== '') {
            addToHistory(currentValue);
        }

        if (res.type === 'exit') {
            return;
        }

        if (res.type === 'math') {
            input.value = res.result;
            requestResize();
            return;
        }

        if (res.type === 'command') {
            input.value = '';
            requestResize();
            return;
        }

        input.value = '';
        requestResize();
    }

    if (e.key === 'Tab') {
        e.preventDefault();

        const val = input.value.trim();
        if (val.startsWith('/')) {
            const partial = val.slice(1).toLowerCase();
            const matches = commandsList.filter(cmd => cmd.startsWith(partial));

            if (matches.length === 1) {
                input.value = '/' + matches[0] + ' ';
                requestResize();
            }
        }
    }

    if (e.key === 'ArrowUp') {
        e.preventDefault();
        if (history.length > 0) {
            if (historyIndex === -1) {
                historyIndex = history.length - 1;
            } else if (historyIndex > 0) {
                historyIndex--;
            }
            input.value = history[historyIndex] || '';
            requestResize();
        }
    } else if (e.key === 'ArrowDown') {
        e.preventDefault();
        if (history.length > 0) {
            if (historyIndex !== -1) {
                historyIndex++;
                if (historyIndex >= history.length) {
                    historyIndex = -1;
                    input.value = '';
                } else {
                    input.value = history[historyIndex] || '';
                }
                requestResize();
            }
        }
    }
});

function addToHistory(command) {
    if (command && (history.length === 0 || history[history.length - 1] !== command)) {
        history.push(command);
    }
    historyIndex = -1;
}

window.addEventListener('DOMContentLoaded', () => {
    input.focus();
    requestResize();
});
