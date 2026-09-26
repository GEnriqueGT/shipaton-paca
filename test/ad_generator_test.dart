import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shipaton_tienda/features/share/ad_generator.dart';

void main() {
  const payload = 'aGVsbG8=';

  test('reads an image from message.images', () {
    final bytes = imageBytesFromOpenRouter({
      'choices': [
        {
          'message': {
            'images': [
              {
                'type': 'image_url',
                'image_url': {'url': 'data:image/png;base64,$payload'},
              },
            ],
          },
        },
      ],
    });

    expect(bytes, Uint8List.fromList(base64Decode(payload)));
  });

  test('reads an image from a content part', () {
    final bytes = imageBytesFromOpenRouter({
      'choices': [
        {
          'message': {
            'content': [
              {
                'type': 'image_url',
                'image_url': {'url': 'data:image/jpeg;base64,$payload'},
              },
            ],
          },
        },
      ],
    });

    expect(bytes, isNotNull);
    expect(bytes, Uint8List.fromList(utf8.encode('hello')));
  });

  test('returns null when the response has no image', () {
    expect(
      imageBytesFromOpenRouter({
        'choices': [
          {
            'message': {'content': 'no image here'},
          },
        ],
      }),
      isNull,
    );
  });

  test('prompt bakes store, title, price and details into the image', () {
    final prompt = studioAdPrompt(
      brandHex: '1B5E20',
      storeName: 'gabrielkike9',
      title: 'playera polo',
      priceLabel: 'Q 10',
      sizes: 'S M L',
      details: 'algodón',
    );
    expect(prompt, contains('#1B5E20'));
    expect(prompt, contains('LEFT HALF'));
    expect(prompt, contains('RIGHT HALF'));
    expect(prompt, contains('back view'));
    expect(prompt, contains('three-quarter'));
    expect(prompt, contains('stylized product name'));
    expect(prompt, contains('gabrielkike9'));
    expect(prompt, contains('playera polo'));
    expect(prompt, contains('S M L'));
    expect(prompt, contains('Q 10'));
    expect(prompt, contains('algodón'));
    expect(prompt, contains('no watermark'));
    expect(prompt.contains('at the bottom'), isFalse);
    expect(prompt.contains('no text'), isFalse);
  });
}
