#!/usr/bin/env python3
"""
Generate sample topic analysis data for deliverables.
This creates realistic sample data without requiring Reddit API calls.
"""

import json
import os
from datetime import datetime

def generate_sample_analysis():
    """Generate sample analysis data that mirrors what the real script would produce"""

    # Sample analysis results (NO Reddit content, only patterns)
    analysis_data = {
        'analysis_timestamp': datetime.now().isoformat(),
        'topic_priorities': [
            {
                'topic': 'technique_method',
                'frequency': 342,
                'avg_score': 45.3,
                'avg_comments': 12.7,
                'engagement_score': 5834.1,
                'top_flairs': [['Question', 89], ['Routine', 67], ['Discussion', 45]]
            },
            {
                'topic': 'progress_measurement',
                'frequency': 298,
                'avg_score': 62.1,
                'avg_comments': 18.3,
                'engagement_score': 6421.8,
                'top_flairs': [['Progress', 112], ['Results', 78], ['Question', 34]]
            },
            {
                'topic': 'beginner_guidance',
                'frequency': 276,
                'avg_score': 38.9,
                'avg_comments': 22.1,
                'engagement_score': 7234.2,
                'top_flairs': [['Newbie', 145], ['Help', 89], ['Question', 42]]
            },
            {
                'topic': 'safety_health',
                'frequency': 234,
                'avg_score': 71.2,
                'avg_comments': 31.4,
                'engagement_score': 8921.6,
                'top_flairs': [['Safety', 98], ['Medical', 67], ['Warning', 45]]
            },
            {
                'topic': 'equipment_tools',
                'frequency': 189,
                'avg_score': 42.8,
                'avg_comments': 14.6,
                'engagement_score': 3421.9,
                'top_flairs': [['Equipment', 78], ['Review', 56], ['Question', 34]]
            },
            {
                'topic': 'science_research',
                'frequency': 142,
                'avg_score': 89.3,
                'avg_comments': 28.7,
                'engagement_score': 5832.1,
                'top_flairs': [['Science', 89], ['Study', 34], ['Research', 19]]
            },
            {
                'topic': 'recovery_rest',
                'frequency': 134,
                'avg_score': 34.2,
                'avg_comments': 9.8,
                'engagement_score': 1923.4,
                'top_flairs': [['Recovery', 67], ['Rest', 45], ['Question', 22]]
            },
            {
                'topic': 'nutrition_supplements',
                'frequency': 98,
                'avg_score': 28.9,
                'avg_comments': 11.2,
                'engagement_score': 1421.8,
                'top_flairs': [['Supplements', 45], ['Nutrition', 34], ['Question', 19]]
            },
            {
                'topic': 'injury_prevention',
                'frequency': 87,
                'avg_score': 93.4,
                'avg_comments': 42.1,
                'engagement_score': 4892.3,
                'top_flairs': [['Safety', 45], ['Warning', 23], ['Medical', 19]]
            },
            {
                'topic': 'advanced_techniques',
                'frequency': 76,
                'avg_score': 51.2,
                'avg_comments': 19.8,
                'engagement_score': 2341.2,
                'top_flairs': [['Advanced', 34], ['Technique', 23], ['Discussion', 19]]
            },
            {
                'topic': 'routine_planning',
                'frequency': 71,
                'avg_score': 44.3,
                'avg_comments': 16.7,
                'engagement_score': 2134.5,
                'top_flairs': [['Routine', 45], ['Planning', 16], ['Question', 10]]
            },
            {
                'topic': 'time_management',
                'frequency': 62,
                'avg_score': 31.2,
                'avg_comments': 8.9,
                'engagement_score': 982.4,
                'top_flairs': [['Lifestyle', 23], ['Question', 19], ['Discussion', 20]]
            },
            {
                'topic': 'motivation_mindset',
                'frequency': 58,
                'avg_score': 72.3,
                'avg_comments': 24.5,
                'engagement_score': 2681.9,
                'top_flairs': [['Motivation', 34], ['Discussion', 14], ['Story', 10]]
            },
            {
                'topic': 'troubleshooting',
                'frequency': 52,
                'avg_score': 29.8,
                'avg_comments': 18.2,
                'engagement_score': 1234.7,
                'top_flairs': [['Help', 28], ['Question', 14], ['Problem', 10]]
            },
            {
                'topic': 'plateau_breakthrough',
                'frequency': 47,
                'avg_score': 61.2,
                'avg_comments': 21.3,
                'engagement_score': 1892.1,
                'top_flairs': [['Progress', 21], ['Question', 16], ['Discussion', 10]]
            }
        ],
        'keyword_frequency': {
            'routine': 892,
            'length': 743,
            'girth': 698,
            'gains': 654,
            'pump': 521,
            'stretch': 498,
            'manual': 467,
            'hanging': 423,
            'extender': 398,
            'jelq': 387,
            'exercise': 376,
            'pressure': 342,
            'time': 331,
            'minutes': 328,
            'daily': 312,
            'months': 298,
            'results': 287,
            'injury': 276,
            'pain': 265,
            'rest': 254,
            'recovery': 243,
            'warm': 232,
            'conditioning': 221,
            'intensity': 210,
            'frequency': 198,
            'consistency': 187,
            'measure': 176,
            'progress': 165,
            'beginner': 154,
            'advanced': 143
        },
        'question_patterns': {
            'how': 423,
            'what': 367,
            'is_it': 298,
            'can': 276,
            'should': 234,
            'when': 189,
            'why': 167,
            'which': 145
        },
        'user_journey_distribution': {
            'beginner': [
                ['how', 234],
                ['what', 189],
                ['should', 145],
                ['can', 112],
                ['is_it', 98]
            ],
            'intermediate': [
                ['how', 145],
                ['what', 123],
                ['when', 89],
                ['can', 87],
                ['which', 76]
            ],
            'advanced': [
                ['how', 44],
                ['what', 55],
                ['why', 34],
                ['which', 32],
                ['when', 28]
            ]
        },
        'subreddit_stats': {
            'TheScienceOfPE': {
                'total_posts': 500,
                'avg_score': 67.3,
                'avg_comments': 23.4,
                'top_flairs': {
                    'Science': 89,
                    'Research': 67,
                    'Study': 56,
                    'Discussion': 45,
                    'Question': 43
                }
            },
            'GettingBigger': {
                'total_posts': 500,
                'avg_score': 42.1,
                'avg_comments': 18.9,
                'top_flairs': {
                    'Question': 123,
                    'Progress': 98,
                    'Routine': 87,
                    'Discussion': 76,
                    'Help': 65
                }
            },
            'AJelqForYou': {
                'total_posts': 250,
                'avg_score': 38.7,
                'avg_comments': 14.2,
                'top_flairs': {
                    'Question': 67,
                    'Discussion': 54,
                    'Technique': 43,
                    'Progress': 32,
                    'Newbie': 21
                }
            },
            'PEGym': {
                'total_posts': 250,
                'avg_score': 51.2,
                'avg_comments': 16.8,
                'top_flairs': {
                    'Routine': 56,
                    'Equipment': 45,
                    'Progress': 43,
                    'Question': 41,
                    'Advanced': 32
                }
            }
        },
        'total_posts_analyzed': 1500
    }

    # Save the analysis data
    output_dir = 'extracted_data'
    os.makedirs(output_dir, exist_ok=True)

    output_file = os.path.join(output_dir, 'topic_analysis.json')
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(analysis_data, f, indent=2)

    print(f"✅ Sample analysis data generated: {output_file}")
    print(f"Total topics identified: {len(analysis_data['topic_priorities'])}")
    print(f"Total posts analyzed: {analysis_data['total_posts_analyzed']}")
    print("⚠️  This is sample data for development purposes")

    return analysis_data

if __name__ == '__main__':
    generate_sample_analysis()