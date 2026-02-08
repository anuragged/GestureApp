import 'dart:math';
import 'package:flutter/material.dart';

/// A robust implementation of the $1 Unistroke Recognizer.
/// Reference: http://depts.washington.edu/madlab/proj/dollar/
class UnistrokeRecognizer {
  static const int numPoints = 64;
  static const double squareSize = 250.0;
  static const double diagonal = 353.55; // sqrt(250^2 + 250^2)
  static const double halfDiagonal = 176.77;
  static const double angleRange = 45.0;
  static const double anglePrecision = 2.0;
  static const double phi = 0.618033988749895; // Golden Ratio

  /// Recognize a gesture from a candidate stroke against a set of templates.
  /// Returns a MatchResult or null if no templates exist.
  MatchResult? recognize(List<Offset> points, List<UnistrokeTemplate> templates) {
    if (templates.isEmpty || points.length < 10) return null;

    final List<Offset> processed = _process(points);
    
    double bestDistance = double.infinity;
    UnistrokeTemplate? bestTemplate;

    for (var template in templates) {
      final double dist = _distanceAtBestAngle(processed, template.points, -angleRange, angleRange, anglePrecision);
      if (dist < bestDistance) {
        bestDistance = dist;
        bestTemplate = template;
      }
    }

    if (bestTemplate == null) return null;

    final double score = 1.0 - (bestDistance / halfDiagonal);
    return MatchResult(bestTemplate.name, score, bestTemplate.data);
  }

  /// Convert raw dictionary/JSON points to a Template
  UnistrokeTemplate createTemplate(String name, List<dynamic> rawPoints, dynamic originalData) {
    // Parse raw maps to Offsets, ignoring nulls (lifts) for Unistroke $1 compatibility
    // treating multi-stroke as a single connected stroke for simplicity.
    List<Offset> points = [];
    for (var p in rawPoints) {
      if (p != null && p is Map) {
        // Handle double/int parsing safely
        double dx = (p['dx'] as num).toDouble();
        double dy = (p['dy'] as num).toDouble();
        points.add(Offset(dx, dy));
      }
    }
    return UnistrokeTemplate(name, _process(points), originalData);
  }

  // --- Processing Steps ---

  List<Offset> _process(List<Offset> points) {
    List<Offset> resampled = _resample(points, numPoints);
    List<Offset> rotated = _rotateToZero(resampled);
    List<Offset> scaled = _scaleToSquare(rotated, squareSize);
    List<Offset> translated = _translateToOrigin(scaled);
    return translated;
  }

  List<Offset> _resample(List<Offset> points, int n) {
    if (points.isEmpty) return [];
    
    double I = _pathLength(points) / (n - 1);
    double D = 0.0;
    
    List<Offset> newPoints = [points[0]];
    
    // Copy to avoid modifying original
    List<Offset> src = List.from(points);
    
    int i = 1;
    while (i < src.length) {
      double d = (src[i] - src[i - 1]).distance;
      if ((D + d) >= I) {
        double qx = src[i - 1].dx + ((I - D) / d) * (src[i].dx - src[i - 1].dx);
        double qy = src[i - 1].dy + ((I - D) / d) * (src[i].dy - src[i - 1].dy);
        Offset q = Offset(qx, qy);
        newPoints.add(q);
        src.insert(i, q); // Insert 'q' at i so the next iteration starts from q
        D = 0.0;
      } else {
        D += d;
      }
      i++;
    }
    
    if (newPoints.length == n - 1) {
      newPoints.add(src.last);
    }
    return newPoints;
  }

  List<Offset> _rotateToZero(List<Offset> points) {
    if (points.isEmpty) return points;
    Offset c = _centroid(points);
    double theta = atan2(c.dy - points[0].dy, c.dx - points[0].dx);
    return _rotateBy(points, -theta);
  }

  List<Offset> _rotateBy(List<Offset> points, double theta) {
    if (points.isEmpty) return points;
    Offset c = _centroid(points);
    List<Offset> newPoints = [];
    for (var p in points) {
      double dx = p.dx - c.dx;
      double dy = p.dy - c.dy;
      newPoints.add(Offset(
        dx * cos(theta) - dy * sin(theta) + c.dx,
        dx * sin(theta) + dy * cos(theta) + c.dy,
      ));
    }
    return newPoints;
  }

  List<Offset> _scaleToSquare(List<Offset> points, double size) {
    if (points.isEmpty) return points;
    Rect bbox = _boundingBox(points);
    double newWidth = bbox.width;
    double newHeight = bbox.height;
    
    // Fallback for lines/dots
    if (newWidth == 0) newWidth = 1;
    if (newHeight == 0) newHeight = 1;

    List<Offset> newPoints = [];
    for (var p in points) {
      double qx = p.dx * (size / newWidth);
      double qy = p.dy * (size / newHeight);
      newPoints.add(Offset(qx, qy));
    }
    return newPoints;
  }

  List<Offset> _translateToOrigin(List<Offset> points) {
    if (points.isEmpty) return points;
    Offset c = _centroid(points);
    List<Offset> newPoints = [];
    for (var p in points) {
      newPoints.add(Offset(p.dx - c.dx, p.dy - c.dy));
    }
    return newPoints;
  }
  
  // --- Helpers ---

  double _pathLength(List<Offset> points) {
    double d = 0.0;
    for (int i = 1; i < points.length; i++) {
      d += (points[i] - points[i - 1]).distance;
    }
    return d;
  }

  Offset _centroid(List<Offset> points) {
    double x = 0.0, y = 0.0;
    for (var p in points) {
      x += p.dx;
      y += p.dy;
    }
    return Offset(x / points.length, y / points.length);
  }

  Rect _boundingBox(List<Offset> points) {
    double minX = double.infinity, maxX = -double.infinity;
    double minY = double.infinity, maxY = -double.infinity;
    for (var p in points) {
      minX = min(minX, p.dx);
      maxX = max(maxX, p.dx);
      minY = min(minY, p.dy);
      maxY = max(maxY, p.dy);
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  double _distanceAtBestAngle(List<Offset> points, List<Offset> T, double a, double b, double threshold) {
    double x1 = phi * a + (1.0 - phi) * b;
    double f1 = _distanceAtAngle(points, T, x1);
    double x2 = (1.0 - phi) * a + phi * b;
    double f2 = _distanceAtAngle(points, T, x2);

    while ((b - a).abs() > threshold) {
      if (f1 < f2) {
        b = x2;
        x2 = x1;
        f2 = f1;
        x1 = phi * a + (1.0 - phi) * b;
        f1 = _distanceAtAngle(points, T, x1);
      } else {
        a = x1;
        x1 = x2;
        f1 = f2;
        x2 = (1.0 - phi) * a + phi * b;
        f2 = _distanceAtAngle(points, T, x2);
      }
    }
    return min(f1, f2);
  }

  double _distanceAtAngle(List<Offset> points, List<Offset> T, double theta) {
    List<Offset> newPoints = _rotateBy(points, theta);
    return _pathDistance(newPoints, T);
  }

  double _pathDistance(List<Offset> pts1, List<Offset> pts2) {
    if (pts1.length != pts2.length) return double.infinity; // Should not happen after resample
    double d = 0.0;
    for (int i = 0; i < pts1.length; i++) {
      d += (pts1[i] - pts2[i]).distance;
    }
    return d / pts1.length;
  }
}

class UnistrokeTemplate {
  final String name;
  final List<Offset> points;
  final dynamic data; // Holds the GestureModel or ID

  UnistrokeTemplate(this.name, this.points, this.data);
}

class MatchResult {
  final String name;
  final double score;
  final dynamic data;

  MatchResult(this.name, this.score, this.data);
}
