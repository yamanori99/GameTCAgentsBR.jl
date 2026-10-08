# GameTCAgentsBR.jl

[English](README.md) | [日本語](README.ja.md)

[![Test](https://img.shields.io/github/actions/workflow/status/yamanori99/GameTCAgentsBR.jl/ci.yml?branch=main&style=flat-square&logo=githubactions&logoColor=white&label=Test)](https://github.com/yamanori99/GameTCAgentsBR.jl/actions/workflows/ci.yml)
[![Codecov](https://img.shields.io/codecov/c/github/yamanori99/GameTCAgentsBR.jl?style=flat-square&logo=codecov&logoColor=white)](https://codecov.io/gh/yamanori99/GameTCAgentsBR.jl)
[![docs-dev](https://img.shields.io/badge/docs-dev-blue?style=flat-square&logo=gitbook&logoColor=white)](https://yamanori99.github.io/GameTCAgentsBR.jl/dev/)
[![Julia 1.13+](https://img.shields.io/badge/Julia-1.13+-9558B2?style=flat-square&logo=julia&logoColor=white)](https://julialang.org/)
[![code style: runic](https://img.shields.io/badge/code_style-%E1%9A%B1%E1%9A%A2%E1%9A%BE%E1%9B%81%E1%9A%B2-black)](https://github.com/fredrikekre/Runic.jl)

GameTCAgentsBR.jl は、有限集団における二者間のゲームを繰り返すシミュレーションである。
各エージェントは、相手の戦略を有限のメモリに記録し、相手のタイプ (集団) ごとに記録を分けて保持できる。
エージェントはその記録を基に、次のゲームで最適な戦略を選択する。

> [!NOTE]
> この実装は、O'Connor (2017) のシミュレーションコードを大規模に汎用化し、拡張したものであり、同文献を参照されたい。
> このシミュレーターは、ナッシュ要求ゲームを扱うために設計されており、demo と test はそのゲームを使う。

## シミュレーションの手順

```txt
PairGame  →  SimConfig                                    src/model.jl
        │
        ▼
run_batch (N 試行)                                        src/batch.jl
        │
        │    各試行:
        │         run_simulation                          src/model.jl
        │         │
        │         └──►  ステップ:
        │               [1] Pair ──► [2] Strategy ──► [3] Update ──► [4] track_callback
        │         │
        │         ▼
        │         count_final_strategies(memory)  ──► 停止時に各戦略が入っている記憶の数  src/analysis.jl
        │
        ▼
    集計  ──►  各戦略が記憶に現れた試行数
```

## セットアップ

Julia 1.13+ が必要である。現時点ではこのパッケージはローカルにあり、このファイルがあるディレクトリからインストールする。

```bash
cd GameTCAgentsBR.jl
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

## 基本的な使い方

```bash
cd GameTCAgentsBR.jl
julia --project=.
```

REPL 上で以下を実行する。各コードブロックは、新しい Julia セッションで実行する。

### 終点の戦略出現率

`demo/run.jl` も具体的なパラメータ設定例が載っているので、参考にしてほしい。

```julia
using GameTCAgentsBR

game = PairGame(
    ["L", "M", "H"],
    [4.5 4.5 4.5; 5.0 5.0 0.0; 5.5 0.0 0.0],
)

config = SimConfig(
    game = game,
    num_agents = 100,
    group_a_ratio = 0.3,
    type_conditioning_ratio_a = 1.0,
    type_conditioning_ratio_b = 1.0,
    memory_length_for_group_a = 10,
    memory_length_for_group_b = 10,
    common_memory_length = 20,
    strategy_override = NoOverride(),
    matching = OnePair(),
    num_initializations = 10000,
    steps_per_initialization = 10_000,
    random_seed = 42,
)

results = run_batch(config)
println(results.b_remembers_a_trial_count)
println(results.a_remembers_b_trial_count)
println(results.a_remembers_a_trial_count)
println(results.b_remembers_b_trial_count)
```

最後の出力は、上から、A が B へ出した戦略、B が A へ出した戦略、A間の戦略、B間の戦略。
それぞれ戦略L、M、H の順の試行数の`Vector{Int}`で出力される。

### 1試行の軌跡を追跡する

途中の次の戦略のシェアは、`track_callback` から `sample_strategy_shares` を呼んで記録する。
この系列だけでは収束や吸引域を示さない。

```julia
using GameTCAgentsBR
using Random

game = PairGame(
    ["L", "M", "H"],
    [4.5 4.5 4.5; 5.0 5.0 0.0; 5.5 0.0 0.0],
)

config = SimConfig(
    game = game,
    num_agents = 100,
    group_a_ratio = 0.3,
    type_conditioning_ratio_a = 1.0,
    type_conditioning_ratio_b = 1.0,
    memory_length_for_group_a = 10,
    memory_length_for_group_b = 10,
    common_memory_length = 20,
    strategy_override = NoOverride(),
    matching = OnePair(),
    num_initializations = 1,
    steps_per_initialization = 1_000,
    random_seed = 42,
)

path = NamedTuple[]
rng = Xoshiro(config.random_seed)
function record(step, memory, config, population)
    shares = sample_strategy_shares(memory, config, population, rng; step)
    push!(path, (; step, shares...))
end
run_simulation(config; seed = config.random_seed, track_callback = record, track_interval = 100)
for sample in path
    println(sample.step, " ", sample.group_a_against_group_b)
end
```

### ゲームの定義

上の例は、両グループがすべての戦略を出せる設定である。`U[i, j]` は、戦略 `i` を出した人が戦略 `j` からもらう点数である。名前は結果ベクトルの順であり、戦略を選ぶ計算には使わない。

B が H を出さない設定ができる。`U` は `3 × 3` のままである。

```julia
U = [
    4.5 4.5 4.5
    5.0 5.0 0.0
    5.5 0.0 0.0
]
game = PairGame(["L", "M", "H"], U, [1, 2, 3], [1, 2])
```

A が 1、2、3 を出し、B が 4 と 5 を出す設定ができる。`U` は `5 × 5` で、左上は A 同士、右上は A が B に向ける点数、左下は B が A に向ける点数、右下は B 同士である。

```julia
game = PairGame(
    ["a", "b", "c", "d", "e"],
    [
        1.0 0.0 0.0 0.2 0.2
        0.0 1.0 0.0 0.2 0.2
        0.0 0.0 1.0 0.2 0.2
        0.2 0.2 0.2 1.0 0.0
        0.2 0.2 0.2 0.0 1.0
    ],
    1:3,
    4:5,
)
```

## `demo/`

以上2つの設定については、`demo/run.jl` で実行することも出来る。

`julia --project=demo demo/run.jl` は、既定の `l45 counts` を実行する。

位置引数は `[case] [mode]` である。ケースは `l40one`、次に `l40`、その後 `l05` から `l45` までで、`l40` は繰り返さない (ナッシュ要求の `L = 0.5 … 4.5`)。

`l40one` は `l40` と同じで、`group_a_ratio = 0` (全員が Group B) である。

`counts` は、停止ステップの記憶に各戦略が現れた試行を数える。`traj` は、1 試行からサンプリングした次の戦略のシェアを示す。一集団のケースが描くのは、その集団の集団内系列だけである。

軌跡のオプション: `--samples N` (目標サンプル数、既定 200)、`--steps N`、`--seed N`。

## エージェントのマッチングルールを操作する

### 例1 `Round`

1ステップで全員を組にする。人数が奇数なら、そのステップの1人は遭遇しない。`Round` はパッケージには無く、この場で足す。

```julia
using GameTCAgentsBR
using Random
import GameTCAgentsBR: match_agents

struct Round <: MatchingRule end

function match_agents(::Round, _step, _memory, population, _config)
    order = randperm(length(population.agents))
    n_pairs = length(order) ÷ 2
    pairs = Vector{Tuple{Int,Int}}(undef, n_pairs)
    for i in 1:n_pairs
        pairs[i] = (order[2i - 1], order[2i])
    end
    return pairs
end

game = PairGame(
    ["L", "M", "H"],
    [4.5 4.5 4.5; 5.0 5.0 0.0; 5.5 0.0 0.0],
)

config = SimConfig(
    game = game,
    num_agents = 100,
    group_a_ratio = 0.3,
    type_conditioning_ratio_a = 1.0,
    type_conditioning_ratio_b = 1.0,
    memory_length_for_group_a = 10,
    memory_length_for_group_b = 10,
    common_memory_length = 20,
    strategy_override = NoOverride(),
    matching = Round(),
    num_initializations = 100,
    steps_per_initialization = 10_000,
    random_seed = 42,
)

results = run_batch(config)
println(results.b_remembers_a_trial_count)
println(results.a_remembers_b_trial_count)
println(results.a_remembers_a_trial_count)
println(results.b_remembers_b_trial_count)
```

### 例2 `SameGroupBias`

同じ集団と確率 0.8 で組にする。希望した側に相手がいないときは、もう一方から引く。

```julia
using GameTCAgentsBR
import GameTCAgentsBR: match_agents

struct SameGroupBias <: MatchingRule
    probability::Float64
end

function match_agents(rule::SameGroupBias, _step, _memory, population, _config)
    agents = population.agents
    n = length(agents)
    a1 = rand(1:n)
    same = Int[]
    other = Int[]
    for i in 1:n
        i == a1 && continue
        if agents[i].group == agents[a1].group
            push!(same, i)
        else
            push!(other, i)
        end
    end
    prefer_same = rand() < rule.probability
    pool = prefer_same ? same : other
    if isempty(pool)
        pool = prefer_same ? other : same
    end
    return [(a1, rand(pool))]
end

game = PairGame(
    ["L", "M", "H"],
    [4.5 4.5 4.5; 5.0 5.0 0.0; 5.5 0.0 0.0],
)

config = SimConfig(
    game = game,
    num_agents = 100,
    group_a_ratio = 0.3,
    type_conditioning_ratio_a = 1.0,
    type_conditioning_ratio_b = 1.0,
    memory_length_for_group_a = 10,
    memory_length_for_group_b = 10,
    common_memory_length = 20,
    strategy_override = NoOverride(),
    matching = SameGroupBias(0.8),
    num_initializations = 100,
    steps_per_initialization = 10_000,
    random_seed = 42,
)

results = run_batch(config)
println(results.b_remembers_a_trial_count)
println(results.a_remembers_b_trial_count)
println(results.a_remembers_a_trial_count)
println(results.b_remembers_b_trial_count)
```

## エージェントの行動ルールを操作する

本モデルは、最良反応がベースである。そのあとで出す戦略は、`strategy_override` で意思決定ルールを変更、操作することもできる。

### 例 `PlayMWhenEmpty`

`override_strategies` にメソッドを足し、`strategy_override` に渡す。呼ばれるメソッドは第一引数の型でディスパッチされる。こういった変更を加えない場合は、`NoOverride` にしておく。

下の例は、相手について読むメモリが空のとき、 M (`2`) を出す操作をしたもの。空スロットは `Int8(-1)` である。

```julia
using GameTCAgentsBR
import GameTCAgentsBR: override_strategies

struct PlayMWhenEmpty <: StrategyOverride end

function row_has_observation(memory, agent, opponent)
    row = if agent.uses_type_conditioning
        if opponent.group == GROUP_A
            memory.group_a_memories[agent.id, :]
        else
            memory.group_b_memories[agent.id, :]
        end
    else
        memory.common_memories[agent.id, :]
    end
    return any(!=(Int8(-1)), row)
end

function override_strategies(::PlayMWhenEmpty, strategy1, strategy2, agent1, agent2,
        step, memory, population, config)
    if !row_has_observation(memory, agent1, agent2)
        strategy1 = Int8(2)
    end
    if !row_has_observation(memory, agent2, agent1)
        strategy2 = Int8(2)
    end
    return strategy1, strategy2
end

game = PairGame(
    ["L", "M", "H"],
    [4.5 4.5 4.5; 5.0 5.0 0.0; 5.5 0.0 0.0],
)

config = SimConfig(
    game = game,
    num_agents = 100,
    group_a_ratio = 0.3,
    type_conditioning_ratio_a = 1.0,
    type_conditioning_ratio_b = 1.0,
    memory_length_for_group_a = 10,
    memory_length_for_group_b = 10,
    common_memory_length = 20,
    strategy_override = PlayMWhenEmpty(),
    matching = OnePair(),
    num_initializations = 100,
    steps_per_initialization = 10_000,
    random_seed = 42,
)

results = run_batch(config)
println(results.b_remembers_a_trial_count)
println(results.a_remembers_b_trial_count)
println(results.a_remembers_a_trial_count)
println(results.b_remembers_b_trial_count)
```

### `PlayMWhenEmpty` の追跡

1試行について、途中の次の戦略のシェアを記録する。

```julia
using GameTCAgentsBR
using Random
import GameTCAgentsBR: override_strategies

struct PlayMWhenEmpty <: StrategyOverride end

function row_has_observation(memory, agent, opponent)
    row = if agent.uses_type_conditioning
        if opponent.group == GROUP_A
            memory.group_a_memories[agent.id, :]
        else
            memory.group_b_memories[agent.id, :]
        end
    else
        memory.common_memories[agent.id, :]
    end
    return any(!=(Int8(-1)), row)
end

function override_strategies(::PlayMWhenEmpty, strategy1, strategy2, agent1, agent2,
        step, memory, population, config)
    if !row_has_observation(memory, agent1, agent2)
        strategy1 = Int8(2)
    end
    if !row_has_observation(memory, agent2, agent1)
        strategy2 = Int8(2)
    end
    return strategy1, strategy2
end

game = PairGame(
    ["L", "M", "H"],
    [4.5 4.5 4.5; 5.0 5.0 0.0; 5.5 0.0 0.0],
)

config = SimConfig(
    game = game,
    num_agents = 100,
    group_a_ratio = 0.3,
    type_conditioning_ratio_a = 1.0,
    type_conditioning_ratio_b = 1.0,
    memory_length_for_group_a = 10,
    memory_length_for_group_b = 10,
    common_memory_length = 20,
    strategy_override = PlayMWhenEmpty(),
    matching = OnePair(),
    num_initializations = 1,
    steps_per_initialization = 1_000,
    random_seed = 42,
)

path = NamedTuple[]
rng = Xoshiro(config.random_seed)
function record(step, memory, config, population)
    shares = sample_strategy_shares(memory, config, population, rng; step)
    push!(path, (; step, shares...))
end
run_simulation(config; seed = config.random_seed, track_callback = record, track_interval = 100)
for sample in path
    println(sample.step, " ", sample.group_a_against_group_b)
end
```

## テスト

```bash
julia --project=. -e 'using Pkg; Pkg.test()'
./.github/jetls-check.sh
```

## 文献

このドキュメントと、`src/GameTCAgentsBR.jl` のモジュール文書に書いてある。

1. O'Connor, C. (2017). The cultural Red King effect. *The Journal of Mathematical Sociology*, 41(3), 155–171. [https://doi.org/10.1080/0022250X.2017.1335723](https://doi.org/10.1080/0022250X.2017.1335723)
2. O'Connor, C. (2019). *The Origins of Unfairness: Social Categories and Cultural Evolution*. Oxford University Press.
3. Bruner, J. P. (2017). Minority (dis)advantage in population games. *Synthese*, 196(1), 413–427. [https://doi.org/10.1007/s11229-017-1487-8](https://doi.org/10.1007/s11229-017-1487-8)
4. Cochran, C., & O'Connor, C. (2019). Inequality and inequity in the emergence of conventions. *Politics, Philosophy & Economics*, 18(3), 264–281. [https://doi.org/10.1177/1470594X19828371](https://doi.org/10.1177/1470594X19828371)
