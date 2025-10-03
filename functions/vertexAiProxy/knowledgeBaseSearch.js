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
    
    // Add variations for common PE abbreviations and related terms
    const expandedTerms = [];
    searchTerms.forEach(term => {
      expandedTerms.push(term);

      // Add variations for PE techniques
      if (term === 'pe' || term === 'penis' || term === 'enlargement') {
        expandedTerms.push('pe', 'penis', 'enlargement', 'training', 'exercise');
      } else if (term === 'jelq' || term === 'jelqing') {
        expandedTerms.push('jelq', 'jelqing', 'girth', 'technique', 'manual');
      } else if (term === 'stretch' || term === 'stretching') {
        expandedTerms.push('stretch', 'stretching', 'length', 'manual', 'traction');
      } else if (term === 'pump' || term === 'pumping') {
        expandedTerms.push('pump', 'pumping', 'vacuum', 'girth', 'equipment');
      } else if (term === 'hang' || term === 'hanging') {
        expandedTerms.push('hang', 'hanging', 'weights', 'length', 'advanced');
      } else if (term === 'kegel' || term === 'kegels') {
        expandedTerms.push('kegel', 'kegels', 'eq', 'pelvic', 'floor', 'exercise');
      } else if (term === 'eq' || term === 'erection' || term === 'quality') {
        expandedTerms.push('eq', 'erection', 'quality', 'kegel', 'cardiovascular');
      } else if (term === 'extender' || term === 'ads') {
        expandedTerms.push('extender', 'ads', 'traction', 'length', 'device');
      } else if (term === 'clamp' || term === 'clamping') {
        expandedTerms.push('clamp', 'clamping', 'girth', 'advanced', 'restriction');
      } else if (term === 'safety' || term === 'safe' || term === 'injury') {
        expandedTerms.push('safety', 'safe', 'injury', 'prevention', 'medical', 'risk');
      } else if (term === 'beginner' || term === 'newbie' || term === 'start') {
        expandedTerms.push('beginner', 'newbie', 'start', 'basic', 'introduction');
      } else if (term === 'routine' || term === 'program' || term === 'schedule') {
        expandedTerms.push('routine', 'program', 'schedule', 'progression', 'training');
      } else if (term === 'gains' || term === 'results' || term === 'growth') {
        expandedTerms.push('gains', 'results', 'growth', 'progress', 'improvement');
      } else if (term === 'warmup' || term === 'warm' || term === 'preparation') {
        expandedTerms.push('warmup', 'warm', 'preparation', 'technique', 'safety');
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
          
          // Calculate relevance score with PE-specific enhancements
          let relevanceScore = 0;
          searchTerms.forEach(term => {
            if (data.title && data.title.toLowerCase().includes(term)) relevanceScore += 3;
            if (data.keywords && data.keywords.some(k => k.includes(term))) relevanceScore += 2;
            if (data.content && data.content.toLowerCase().includes(term)) relevanceScore += 1;
          });

          // Boost safety content (priority 9-10)
          const priority = data.priority || 5;
          if (priority >= 9) {
            relevanceScore += 5; // Significant boost for safety content
          } else if (priority >= 7) {
            relevanceScore += 2; // Moderate boost for high priority content
          }

          // Category-based boosting for relevant searches
          const category = data.category || '';
          if (searchQuery.includes('safety') || searchQuery.includes('injury') || searchQuery.includes('pain')) {
            if (category === 'safety') relevanceScore += 3;
          }
          if (searchQuery.includes('beginner') || searchQuery.includes('start')) {
            if (category === 'progression') relevanceScore += 2;
          }

          results.push({
            title: data.title,
            snippet: data.content ? data.content.substring(0, 200) + '...' : '',
            confidence: Math.min(0.95, 0.5 + (relevanceScore * 0.1)),
            fullContent: data.content || data.content_text || '',
            type: data.type || data.category || 'knowledge',
            category: category,
            priority: priority,
            relevanceScore: relevanceScore,
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
    
    // Sort by relevance score first, then confidence, prioritizing safety content
    results.sort((a, b) => {
      // Prioritize safety content (priority 9-10)
      if ((a.priority >= 9) && (b.priority < 9)) return -1;
      if ((b.priority >= 9) && (a.priority < 9)) return 1;

      // Then sort by relevance score
      if (a.relevanceScore !== b.relevanceScore) {
        return b.relevanceScore - a.relevanceScore;
      }

      // Finally by confidence
      return b.confidence - a.confidence;
    });

    console.log(`📊 Returning ${Math.min(results.length, 5)} results, sorted by safety priority and relevance`);
    return results.slice(0, 5);
    
  } catch (error) {
    console.error('Error searching knowledge base:', error);
    // Return empty array if search fails
    return [];
  }
};

module.exports = { searchKnowledgeBase };