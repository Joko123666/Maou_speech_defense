class_name ShopProductData
extends Resource

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var icon: Texture2D
@export var product_type: StringName
@export var content_id: StringName
@export var price: int = 0
@export var discovery_achievement_id: StringName
@export var required_product_ids: Array[StringName] = []
@export var granted_feature_ids: Array[StringName] = []
@export var granted_content_ids: Array[StringName] = []

func configure(
	product_id: StringName,
	title: String,
	detail: String,
	type: StringName,
	target_content_id: StringName,
	cost: int,
	achievement_id: StringName
) -> ShopProductData:
	id = product_id
	display_name = title
	description = detail
	product_type = type
	content_id = target_content_id
	price = cost
	discovery_achievement_id = achievement_id
	granted_content_ids = [target_content_id]
	return self
