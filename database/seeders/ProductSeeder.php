<?php
namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Product;

class ProductSeeder extends Seeder
{
    public function run(): void
    {
        Product::truncate();
        Product::create(['title'=>'Basic Plan','description'=>'One-time demo item','price_inr'=>199]);
        Product::create(['title'=>'Pro Plan','description'=>'Advanced demo item','price_inr'=>299]);
        Product::create(['title'=>'Platinum Plan','description'=>'Full demo item','price_inr'=>499]);
    }
}
