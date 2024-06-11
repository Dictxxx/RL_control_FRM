import numpy as np
import os
from ppo_agent import PPO
import csv


def compute_reward(s0,s_t):
    sx0 = s0[0]
    sy0 = s0[1]
    sx_t = s_t[0]
    sy_t = s_t[1]
    r0 = np.sqrt(sx0**2+sy0**2)
    rt = np.sqrt(sx_t**2+sy_t**2)
    cos_theta = ( (sx0-sx_t)*sx0 + (sy0-sy_t)*sy0 ) / (r0*np.sqrt( np.square(sx_t-sx0)+np.square(sy_t-sy0) ) )
    #>> np.exp(-50*rt)
    r1 = np.exp(-(1-cos_theta))
    r2 = np.min([1.0 , np.exp(-10*(rt-0.005))])
    r3 = np.min([2.0 , 2*np.exp(-1000*(rt-0.005))])
    R = r1 + r2 + r3

    return R, rt

def reset(sx0,sy0):
    os.chdir(f'../{SIM_DIR}')
    os.system(f'cp ./restart_base.fld ./restart.fld')
    os.chdir(f'../{DRL_DIR}')

    fact = open(f'../{SIM_DIR}/trajectory_init.plt', 'w')
    fact.write('%.15f %.15f\n' % (sx0, sy0))
    fact.close()

    f = open(f'../{SIM_DIR}/Q.txt', 'w')
    f.write('%.15f %.15f \n' % (1.0, 1.0))
    f.close()

    os.chdir(f'../{SIM_DIR}')
    os.system(f'nekmpi FRM {NCPU}')
    os.chdir(f'../{DRL_DIR}')

    data= np.loadtxt(f'../{SIM_DIR}/trajectory_init.plt')
    kx0=data[2]; ky0=data[3]

    s = [sx0,sy0,kx0*100,ky0*100,kx0*500,ky0*500]
    s = np.array(s)
    return s

def step(Qnow):
    f = open(f'../{SIM_DIR}/Q.txt', 'w')
    f.write('%.15f %.15f \n' % (Qnow[0], Qnow[1]))
    f.close()
    
    os.chdir(f'../{SIM_DIR}')
    os.system(f'nekmpi FRM {NCPU}')
    os.chdir(f'../{DRL_DIR}')
    
    data= np.loadtxt(f'../{SIM_DIR}/trajectory_hist_t.dat')
    sx_t = data[-1,0]; sy_t = data[-1,1]
    kx_t = data[-1,2]; ky_t = data[-1,3]
    kx_t1 = data[-2,2]; ky_t1 = data[-2,3]
    ax = (kx_t-kx_t1)/0.2; ay = (ky_t-ky_t1)/0.2
    f = open(f'../{SIM_DIR}/trajectory_init.plt', 'w')
    f.write('%.15f %.15f \n' % (sx_t, sy_t))
    f.close()
    
    os.chdir(f'../{SIM_DIR}')
    os.system('cp ./FRM0.f00001 restart.fld')
    os.chdir(f'../{DRL_DIR}')

    s_t = [sx_t,sy_t,kx_t*100,ky_t*100,ax*100,ay*100]
    s_t = np.array(s_t)
    return s_t


def output_data(episode_number, step, action, reward, state_t, s0, rt):
    name = "output.plt"
    state_file = "state.plt"
    if (not os.path.exists("test_results")):
        os.mkdir("test_results")
    if (not os.path.exists("test_results/" + name)):
        with open("test_results/" + name, "w") as csv_file:
            spam_writer = csv.writer(csv_file, delimiter=",", lineterminator="\n")
            spam_writer.writerow(['Episode', 'Step', 'Action1', 'Action2', 'Reward', 'rt', 'sx', 'sy', 'kx', 'ky'])
            spam_writer.writerow([episode_number, step, action[0], action[1], reward, rt, state_t[0], state_t[1], state_t[2], state_t[3]])
        with open("test_results/" + state_file, "w") as csv_file:
            spam_writer = csv.writer(csv_file, delimiter=",", lineterminator="\n")
            spam_writer.writerow([s0,state_t])
    else:
        with open("test_results/" + name, "a") as csv_file:
            spam_writer = csv.writer(csv_file, delimiter=",", lineterminator="\n")
            spam_writer.writerow([episode_number, step, action[0], action[1], reward, rt, state_t[0], state_t[1], state_t[2], state_t[3]])
        with open("test_results/" + state_file, "a") as csv_file:
            spam_writer = csv.writer(csv_file, delimiter=",", lineterminator="\n")
            spam_writer.writerow([s0,state_t])

def output_hist(episode_number, rt, all_ep_r):
    name = "train_hist.plt"
    if (not os.path.exists("test_results")):
        os.mkdir("test_results")
    if (not os.path.exists("test_results/" + name)):
        with open("test_results/" + name, "w") as csv_file:
            spam_writer = csv.writer(csv_file, delimiter=",", lineterminator="\n")
            spam_writer.writerow(['Episode', 'rt', 'ep_r'])
            spam_writer.writerow([episode_number, rt, all_ep_r])
    else:
        with open("test_results/" + name, "a") as csv_file:
            spam_writer = csv.writer(csv_file, delimiter=",", lineterminator="\n")
            spam_writer.writerow([episode_number, rt, all_ep_r])

#------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------

os.system('rm -r test_results')

#:: How many cores to run
NCPU = 20
SIM_DIR = 'CFD'
DRL_DIR = 'r01_80'

act_lim = 2
ppo = PPO(6, 2, [300,300], act_lim)
model_id = '_test'
ppo.restore(model_id)

ic = 0.1
r0 = ic * np.sqrt(2)
theta = 80

x_ic = -r0 * np.cos(np.deg2rad(theta))
y_ic = r0 * np.sin(np.deg2rad(theta))

x_ic3 = x_ic
y_ic3 = y_ic

max_episode = 3
max_step = 50

r_threshold = 0.005

all_ep_r = []

for i in range(max_episode):
    s = reset(x_ic3,y_ic3)
    STOP = False
    print(f'>>> The shape of s: {s.shape}')
    ep_r = 0

    for j in range(max_step):
        a = ppo.choose_action(s)
        s_ = step(a)
        r, rt = compute_reward(s, s_)
        if (rt < r_threshold):
            STOP = True
        output_data(i+1, j+1, a, r, s_, s, rt)
        s = s_
        ep_r += r

        if STOP:
            break

    if i == 0:
        all_ep_r.append(ep_r)
    else:
        all_ep_r.append(all_ep_r[-1]*0.9 + ep_r*0.1)

    output_hist(i+1, rt, all_ep_r[-1])

