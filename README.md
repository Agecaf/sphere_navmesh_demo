# Sphere Navmesh Demo

You can find the source code in the "master" branch.

You can find an [online demo here](https://agecaf.itch.io/spherical-navigation-mesh), the page's password is `sphere`.

# How does it work?

1. We generate some random points on the sphere.
2. We make some obstacles from those points.
3. Then we triangulate everything to get a navigation mesh. This step still has bugs.
4. We then use the navigation mesh to find paths using an A* algorithm,
5. which we then simplify, this step still has potential further simplification.

# Where can I find the cool bits of code?

- [Triangulation Utils](https://github.com/Agecaf/sphere_navmesh_demo/blob/master/scripts/utils/triangulation_utils.gd) has most of the triangulation logic.
- [NavMeshSphere](https://github.com/Agecaf/sphere_navmesh_demo/blob/master/game/navmesh/navmesh_sphere.gd) has our navigation mesh.
- [ParallelThread](https://github.com/Agecaf/sphere_navmesh_demo/blob/master/game/demo/parallel_thread.gd) is where our navigation mesh is built.
- [Pathfinder](https://github.com/Agecaf/sphere_navmesh_demo/blob/master/game/pathfinder/pathfinder.gd) is responsible for finding paths.

