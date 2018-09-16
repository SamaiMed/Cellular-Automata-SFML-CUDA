#include <stdio.h>
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <stdlib.h>
#include "SFML\Graphics.hpp"
#define N  64


int onedim(int n, int i, int j) { return n*i + j; }

void Update(int w, int h, int *map, int *stats) {
	for (int i = 1; i < w - 1; i++) {
		for (int j = 1; j < h - 1; j++) {

			int a = map[onedim(h, i - 1, j + 1)] + map[onedim(h, i, j + 1)] + map[onedim(h, i + 1, j + 1)] +
				map[onedim(h, i - 1, j)] + 0 + map[onedim(h, i + 1, j)] +
				map[onedim(h, i - 1, j - 1)] + map[onedim(h, i, j - 1)] + map[onedim(h, i + 1, j - 1)];

			if (map[onedim(h, i, j)] == 1) {
				stats[onedim(h, i, j)] = (int)((a == 2 || a == 3) ? 1 : 0);
			}
			else {
				stats[onedim(h, i, j)] = (int)(a == 3 ? 1 : 0);
			}
		}
	}	
}

__global__ void Update_CUDA(int w, int h, int *map, int *stats) {

	int row = blockIdx.x * blockDim.x + threadIdx.x;
	int col = blockIdx.y * blockDim.y + threadIdx.y;
	int stride_x = gridDim.x * blockDim.x;
	int stride_y = gridDim.y * blockDim.y;
	if (row > 0 && col > 0 && row < w - 1 && col < h - 1) {
		for (int i = row; i < w - 1; i += stride_x) {
			for (int j = col; j < h - 1; j += stride_y) {

				int a = map[h*(i - 1)+j + 1] + map[h*i+j + 1] + map[h*(i + 1)+j + 1] +
					map[h*(i - 1)+j] + 0 + map[h*(i + 1)+j] +
					map[h*(i - 1)+j - 1] + map[h*i+j - 1] + map[h*(i + 1)+j - 1];

				if (map[h*i+j] == 1) {
					stats[h*i+j] = (int)((a == 2 || a == 3) ? 1 : 0);
				}
				else {
					stats[h*i+j] = (int)(a == 3 ? 1 : 0);
				}
			}
		}
	}

	
}


int main() {
	const int w = 1300;
	const int h = 766;
	const float wf = (float)w;
	const float hf = (float)h;
	int *map, *stats;
	sf::Uint8 *pixels=new sf::Uint8[w * h * 4];
	sf::RenderWindow window(sf::VideoMode(w, h), "SFML works!");

	sf::Clock clock;
	sf::Time time;

	sf::RectangleShape player(sf::Vector2f(wf, hf));
	player.setPosition(0.f, 0.f);
	sf::Texture player_texture;
	sf::Image image;
	sf::Image *imo;
	image.create(w, h);
	
	cudaMallocManaged(&map, w*h*sizeof(int));
	cudaMallocManaged(&stats, w*h*sizeof(int));
	


	dim3 threads_per_block(32, 32, 1); // A 16 x 16 block threads
	dim3 number_of_blocks((w / threads_per_block.x) + 1, (h / threads_per_block.y) + 1, 1);

	for (int i = 0; i < w; i++) {
		for (int j = 0; j < h; j++) {
			map[onedim(h,i,j)] = 0;
			if (((float)rand() / (RAND_MAX + 1.0)) < 0.75f) {
				image.setPixel(i, j, sf::Color::Blue);
				map[onedim(h,i,j)] = 1;
			}
		}
	}
	player_texture.loadFromImage(image);
	player.setTexture(&player_texture);

	while (window.isOpen())
	{
		time = clock.getElapsedTime();
		clock.restart().asSeconds();
		float fps = 1.0f / time.asSeconds();

		printf("FPS:: %f \r", fps);
		sf::Event event;

		while (window.pollEvent(event))
		{

			switch (event.type)
			{
			case sf::Event::Closed:
				window.close();
				break;
			case sf::Event::Resized:
				printf("Windows size : %d, %d \n", event.size.height, event.size.width);
				//window.setView(sf::View(sf::FloatRect(0, 0, event.size.width, event.size.height)));
				break;
			case sf::Event::TextEntered:
				if (event.text.unicode < 128) {
					printf("%c", event.text.unicode);
				}
				break;
			}


		}
	//	Update(w, h, map,stats, &image); // for test 
		Update_CUDA << < number_of_blocks, threads_per_block >> > (w, h, map, stats);
		cudaDeviceSynchronize();

		for (int i = 0; i < w; i++) {
			for (int j = 0; j < h; j++) {
				map[onedim(h, i, j)] = stats[onedim(h, i, j)];
				if (map[onedim(h, i, j)] == 1) {
					image.setPixel(i, j, sf::Color::Blue);
				}
				else {
					image.setPixel(i, j, sf::Color::Black);
				}
			}
		}

		player_texture.loadFromImage(image);
		player.setTexture(&player_texture);
		window.clear();
		window.draw(player);
		window.display();
	}

	cudaFree(map); cudaFree(stats);
	return 0;
}