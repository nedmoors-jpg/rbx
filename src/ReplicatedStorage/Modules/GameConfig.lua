local config = {
    LobbyDuration = 20,
    RoundDuration = 150,
    PostRoundDuration = 12,
    CrystalRespawnTime = 10,
    CrystalCount = 18,
    CrystalValue = 5,
    EnemySpawnDelay = 8,
    EnemySpawnInterval = 18,
    MaxEnemies = 6,
    EnemyDamage = 20,
    EnemySpeed = 12,
    AmbientLight = Color3.fromRGB(65, 100, 160),
    FogColor = Color3.fromRGB(19, 27, 41),
    FogEnd = 180,
    SpawnLocations = {
        Vector3.new(0, 6, 0),
        Vector3.new(32, 6, -24),
        Vector3.new(-28, 6, 27),
        Vector3.new(50, 7, 19),
        Vector3.new(-55, 8, -18)
    },
    CrystalSpawnPositions = {
        Vector3.new(0, 4, 0),
        Vector3.new(12, 5, 18),
        Vector3.new(-16, 5, -20),
        Vector3.new(24, 6, -35),
        Vector3.new(-38, 7, 10),
        Vector3.new(46, 5, 8),
        Vector3.new(8, 4, -42),
        Vector3.new(-4, 4, 36),
        Vector3.new(-26, 6, 44),
        Vector3.new(34, 7, 33),
        Vector3.new(-40, 7, -34),
        Vector3.new(18, 5, 44),
        Vector3.new(-52, 5, -6),
        Vector3.new(58, 6, -14),
        Vector3.new(-20, 5, 14),
        Vector3.new(6, 7, 58),
        Vector3.new(-8, 6, -58),
        Vector3.new(52, 6, 48)
    },
    EnemySpawnPositions = {
        Vector3.new(-60, 6, 60),
        Vector3.new(60, 6, -60),
        Vector3.new(-60, 6, -60),
        Vector3.new(60, 6, 60),
        Vector3.new(0, 6, 60),
        Vector3.new(0, 6, -60)
    }
}

return config
