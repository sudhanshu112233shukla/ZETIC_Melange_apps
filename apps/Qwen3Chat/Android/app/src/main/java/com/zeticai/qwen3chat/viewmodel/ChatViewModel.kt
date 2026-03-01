package com.zeticai.qwen3chat.viewmodel

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.zeticai.qwen3chat.data.ChatRepository
import com.zeticai.qwen3chat.data.model.ChatMessage
import com.zeticai.qwen3chat.llm.LLMService
import com.zeticai.qwen3chat.llm.TokenSync
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

class ChatViewModel(application: Application) : AndroidViewModel(application) {
    private val chatRepository = ChatRepository(application)
    private val llmService = LLMService(application)
    
    private val _messages = MutableStateFlow<List<ChatMessage>>(emptyList())
    val messages: StateFlow<List<ChatMessage>> = _messages.asStateFlow()
    
    private val _isGenerating = MutableStateFlow(false)
    val isGenerating: StateFlow<Boolean> = _isGenerating.asStateFlow()
    
    private val _currentStreamText = MutableStateFlow("")
    val currentStreamText: StateFlow<String> = _currentStreamText.asStateFlow()
    
    private val _lastGenerationTime = MutableStateFlow(0L)
    val lastGenerationTime: StateFlow<Long> = _lastGenerationTime.asStateFlow()
    
    private val _lastTokenCount = MutableStateFlow(0)
    val lastTokenCount: StateFlow<Int> = _lastTokenCount.asStateFlow()
    
    private var generationJob: Job? = null
    
    init {
        llmService.initialize()
        loadHistory()
    }
    
    private fun loadHistory() {
        viewModelScope.launch {
            _messages.value = chatRepository.loadMessages()
        }
    }
    
    private fun saveHistory(msgs: List<ChatMessage>) {
        viewModelScope.launch {
            chatRepository.saveMessages(msgs)
        }
    }
    
    fun sendMessage(text: String) {
        if (text.isBlank()) return
        
        val userMsg = ChatMessage(isUser = true, text = text)
        val updatedList = _messages.value + userMsg
        _messages.value = updatedList
        saveHistory(updatedList)
        
        // Simple Context Builder
        val prompt = buildPrompt(updatedList)
        
        _currentStreamText.value = ""
        _isGenerating.value = true
        
        generationJob = viewModelScope.launch {
            try {
                llmService.generateResponse(prompt).collect { sync ->
                    when (sync) {
                        is TokenSync.Token -> {
                            _currentStreamText.update { it + sync.text }
                        }
                        is TokenSync.Done -> {
                            finalizeResponse()
                            _lastGenerationTime.value = sync.durationMs
                            _lastTokenCount.value = sync.totalTokens
                        }
                    }
                }
            } catch (e: Exception) {
                _currentStreamText.value = "Error generating response."
                finalizeResponse()
            }
        }
    }
    
    private fun finalizeResponse() {
        if (_currentStreamText.value.isNotBlank()) {
            val aiMsg = ChatMessage(isUser = false, text = _currentStreamText.value)
            val updatedList = _messages.value + aiMsg
            _messages.value = updatedList
            saveHistory(updatedList)
        }
        _currentStreamText.value = ""
        _isGenerating.value = false
    }
    
    fun stopGeneration() {
        generationJob?.cancel()
        llmService.stop()
        finalizeResponse()
    }
    
    fun clearHistory() {
        viewModelScope.launch {
            chatRepository.clearHistory()
            _messages.value = emptyList()
        }
    }
    
    override fun onCleared() {
        super.onCleared()
        // Cleanup contract
        llmService.clear()
    }
    
    private fun buildPrompt(messages: List<ChatMessage>): String {
        return messages.takeLast(10).joinToString("
") { 
            if (it.isUser) "User: ${it.text}" else "Assistant: ${it.text}"
        } + "
Assistant: "
    }
}
