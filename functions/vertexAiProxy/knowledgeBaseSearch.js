/**
 * Enhanced knowledge base search functionality
 */

const searchKnowledgeBase = async (query, db) => {
  try {
    console.log(`🔍 Searching knowledge base for: "${query}"`);
    
    // Convert query to lowercase for searching
    const searchQuery = query.toLowerCase();
    
    // Extract search terms - don't filter out short terms for abbreviations
    const searchTerms = searchQuery.split(/\s+/).filter(term => term.length > 0);
    
    // Add variations for common abbreviations and related terms
    const expandedTerms = [];
    searchTerms.forEach(term => {
      expandedTerms.push(term);

      // Add variations for AM1, AM2, AM3
      if (term === 'am1' || term === 'am' || term === '1' || term === '1?') {
        expandedTerms.push('am1', 'am 1', 'angion method 1', 'angion 1', 'angion', 'method');
      } else if (term === 'am2' || term === '2' || term === '2?') {
        expandedTerms.push('am2', 'am 2', 'angion method 2', 'angion 2');
      } else if (term === 'am3' || term === '3' || term === '3?' || term === 'vascion') {
        expandedTerms.push('am3', 'am 3', 'angion method 3', 'angion 3', 'vascion');
      } else if (term.includes('angion')) {
        expandedTerms.push('angion', 'method', 'am1', 'am2', 'am3');
      } else if (term === 'pelvic' || term === 'floor' || term === 'tight') {
        expandedTerms.push('pelvic', 'floor', 'kegel', 'relaxation', 'am2', 'angion');
      } else if (term === 'warmup' || term === 'warm' || term === 'burst' || term === 'pyramid') {
        expandedTerms.push('warmup', 'preparation', 'technique', 'progression', 'am1', 'beginner');
      } else if (term === 'progression' || term === 'weekly' || term === 'add') {
        expandedTerms.push('progression', 'duration', 'minutes', 'gradual', 'timeline');
      }
    });
    
    // Remove duplicates and limit to 10 (Firestore limit)
    const uniqueTerms = [...new Set(expandedTerms)].slice(0, 10);
    
    // Query the knowledge base collection
    const knowledgeRef = db.collection('ai_coach_knowledge');
    const results = [];
    const processedIds = new Set();
    
    console.log(`📊 Querying ai_coach_knowledge collection with ${uniqueTerms.length} terms`);
    
    // Search by keywords if we have search terms
    if (uniqueTerms.length > 0) {
      const snapshot = await knowledgeRef
        .where('keywords', 'array-contains-any', uniqueTerms)
        .limit(10)
        .get();
      
      console.log(`✅ Found ${snapshot.size} documents matching keywords`);
      
      snapshot.forEach(doc => {
        const data = doc.data();
        if (!processedIds.has(doc.id)) {
          processedIds.add(doc.id);
          
          // Calculate relevance score
          let relevanceScore = 0;
          searchTerms.forEach(term => {
            if (data.title && data.title.toLowerCase().includes(term)) relevanceScore += 3;
            if (data.keywords && data.keywords.some(k => k.includes(term))) relevanceScore += 2;
            if (data.searchableContent && data.searchableContent.includes(term)) relevanceScore += 1;
          });
          
          results.push({
            title: data.title,
            snippet: data.content ? data.content.substring(0, 200) + '...' : '',
            confidence: Math.min(0.95, 0.5 + (relevanceScore * 0.1)),
            fullContent: data.content || data.content_text || '',
            type: data.type || data.category || 'knowledge',
            metadata: data.metadata || {}
          });
        }
      });
    }
    
    // If no results, do a broader search in searchableContent
    if (results.length === 0) {
      const allDocs = await knowledgeRef.limit(20).get();
      
      allDocs.forEach(doc => {
        const data = doc.data();
        const searchableContent = (data.searchableContent || '').toLowerCase();
        const title = (data.title || '').toLowerCase();
        const content = data.content || data.content_text || '';
        
        // Check if any search term appears in searchable content or title
        const matches = searchTerms.some(term => 
          searchableContent.includes(term) || 
          title.includes(term) ||
          content.toLowerCase().includes(term)
        );
        
        if (matches && !processedIds.has(doc.id)) {
          processedIds.add(doc.id);
          results.push({
            title: data.title,
            snippet: content.substring(0, 200) + '...',
            confidence: 0.7,
            fullContent: content,
            type: data.type || data.category || 'knowledge',
            metadata: data.metadata || {}
          });
        }
      });
    }
    
    // Sort by confidence and return top results
    results.sort((a, b) => b.confidence - a.confidence);
    return results.slice(0, 5);
    
  } catch (error) {
    console.error('Error searching knowledge base:', error);
    // Return empty array if search fails
    return [];
  }
};

module.exports = { searchKnowledgeBase };