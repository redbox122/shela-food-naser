// ignore_for_file: camel_case_types

class SearchFilterModel {
  String? research_Name = '';
  String? product_arrangement = '';
  String? id_category = '';
  String? id_stores = '';
  String? discount = '';
  String? min = '';
  String? max = '';
  String? offset = '1';
  String? limit = '10';

  SearchFilterModel({
    this.research_Name,
    this.product_arrangement,
    this.id_category,
    this.id_stores,
    this.discount,
    this.min,
    this.max,
    this.offset,
    this.limit,
  });
}
