const statusEl = document.getElementById('status');
const readBtn = document.getElementById('readBtn');

function setStatus(message, isError = false) {
  statusEl.textContent = message;
  statusEl.style.color = isError ? '#b00020' : '';
}

async function getSelectedText() {
  const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });

  if (!tab || typeof tab.id !== 'number') {
    throw new Error('Aucun onglet actif trouvé.');
  }

  const [{ result }] = await chrome.scripting.executeScript({
    target: { tabId: tab.id },
    func: () => window.getSelection()?.toString().trim() ?? ''
  });

  return result;
}

function speakFrench(text) {
  chrome.tts.stop();

  chrome.tts.speak(text, {
    lang: 'fr-FR',
    rate: 1,
    pitch: 1,
    volume: 1,
    enqueue: false
  });
}

readBtn.addEventListener('click', async () => {
  setStatus('Recherche de texte sélectionné…');

  try {
    const selectedText = await getSelectedText();

    if (!selectedText) {
      setStatus('Sélectionnez un texte dans la page puis réessayez.', true);
      return;
    }

    speakFrench(selectedText);
    setStatus('Lecture en cours.');
  } catch (error) {
    setStatus(`Erreur : ${error.message}`, true);
  }
});
