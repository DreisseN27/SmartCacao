<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\User;

class AuthController extends Controller
{
    public function sync(Request $request)
    {
        $request->validate([
            'firebase_uid' => 'required|string',
            'email' => 'required|email',
            'first_name' => 'required|string',
            'middle_initial' => 'nullable|string',
            'last_name' => 'required|string',
            'role' => 'nullable|string',
        ]);

        $user = User::updateOrCreate(
            ['firebase_uid' => $request->firebase_uid],
            [
                'email' => $request->email,
                'first_name' => $request->first_name,
                'middle_initial' => $request->middle_initial,
                'last_name' => $request->last_name,
                'role' => $request->role ?? 'farmer',
            ]
        );

        return response()->json([
            'message' => 'User synced successfully',
            'user' => $user
        ]);
    }

    public function profile(string $firebaseUid)
    {
        $user = User::where('firebase_uid', $firebaseUid)->first();

        if (!$user) {
            return response()->json([
                'message' => 'User not found',
            ], 404);
        }

        return response()->json([
            'user' => $user,
        ]);
    }
}