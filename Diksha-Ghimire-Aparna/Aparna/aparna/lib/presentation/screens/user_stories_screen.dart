import 'package:flutter/material.dart';
import '../../data/models/story_model.dart';
import '../../data/services/story_service.dart';

class UserStoriesScreen extends StatefulWidget {
  const UserStoriesScreen({Key? key}) : super(key: key);

  @override
  State<UserStoriesScreen> createState() => _UserStoriesScreenState();
}

class _UserStoriesScreenState extends State<UserStoriesScreen> {
  final StoryService _storyService = StoryService();
  List<UserStory> _stories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  Future<void> _loadStories() async {
    try {
      final stories = await _storyService.fetchStories();
      setState(() {
        _stories = stories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load stories: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // final mediaQuery = MediaQuery.of(context);
    // final size = mediaQuery.size;
    // final horizontalPadding = (size.width * 0.05).clamp(16.0, 32.0);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.pink),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Stories', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.pink),
            onPressed: _showAddStoryDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.pink))
          : _stories.isEmpty
              ? const Center(child: Text('No stories found'))
              : ListView.builder(
                  itemCount: _stories.length,
                  itemBuilder: (context, index) {
                    return _buildStoryCard(_stories[index]);
                  },
                ),
    );
  }

  void _showAddStoryDialog() {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    final nameController = TextEditingController();
    bool isAnonymous = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(width: 24),
                          const Text(
                            'Add your story',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(Icons.cancel, color: Colors.grey, size: 28),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Do you want to add your name?',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ),
                          Checkbox(
                            value: !isAnonymous,
                            onChanged: (val) {
                              setModalState(() => isAnonymous = !(val ?? false));
                            },
                            activeColor: const Color(0xFFF8A5A5),
                          ),
                        ],
                      ),
                      if (!isAnonymous) ...[
                        const SizedBox(height: 10),
                        TextField(
                          controller: nameController,
                          decoration: _inputDecoration('Your Name'),
                        ),
                      ],
                      const SizedBox(height: 15),
                      TextField(
                        controller: titleController,
                        decoration: _inputDecoration('Title'),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: messageController,
                        maxLines: 5,
                        decoration: _inputDecoration('Message'),
                      ),
                      const SizedBox(height: 25),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (titleController.text.isEmpty || messageController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please fill all fields')),
                              );
                              return;
                            }
                            try {
                              await _storyService.createStory(
                                title: titleController.text,
                                content: messageController.text,
                                isAnonymous: isAnonymous,
                                authorName: nameController.text,
                              );
                              if (mounted) {
                                Navigator.pop(context);
                                _loadStories();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Story submitted successfully!')),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFFF8A5A5)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Submit',
                            style: TextStyle(
                              color: Color(0xFFF8A5A5),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFF8A5A5), width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFF8A5A5), width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFF8A5A5), width: 1),
      ),
    );
  }

  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     backgroundColor: Colors.white,
  //     body: SafeArea(
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Padding(
  //             padding: const EdgeInsets.all(20),
  //             child: Row(
  //               children: [
  //                 GestureDetector(
  //                   onTap: () => Navigator.pop(context),
  //                   child: const Icon(
  //                     Icons.arrow_back_ios,
  //                     color: Color(0xFFF8A5A5),
  //                     size: 28,
  //                   ),
  //                 ),
  //                 const SizedBox(width: 10),
  //                 const Text(
  //                   'User Stories',
  //                   style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
  //                 ),
  //               ],
  //             ),
  //           ),
  //           Expanded(
  //             child: _isLoading
  //                 ? const Center(child: CircularProgressIndicator(color: Color(0xFFF8A5A5)))
  //                 : ListView.builder(
  //                     padding: const EdgeInsets.symmetric(horizontal: 20),
  //                     itemCount: _stories.length + 1,
  //                     itemBuilder: (context, index) {
  //                       if (index == _stories.length) {
  //                         return _buildAddYourStoryBtn();
  //                       }
  //                       return _buildStoryCard(_stories[index]);
  //                     },
  //                   ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildStoryCard(UserStory story) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF8A5A5).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF8A5A5).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: const Color(0xFFF8A5A5).withOpacity(0.3)),
            ),
            child: Text(
              story.isAnonymous ? 'Anonymous' : story.authorName,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            story.content,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
              height: 1.5,
              wordSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

}
