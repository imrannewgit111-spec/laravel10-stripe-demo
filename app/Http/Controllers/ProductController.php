<?php
namespace App\Http\Controllers;

use App\Models\Product;

class ProductController extends Controller
{
    public function index()
    {
        $products = Product::latest()->paginate(12);
        return view('products.index', compact('products'));
    }
    public function show(Product $product)
    {
        return view('products.show', compact('product'));
    }
}
