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
    
    r1 = np.exp(-2*(1-cos_theta))
    r2 = np.min([1.0 , np.exp(-30*(rt-0.0025))])
    R = r1 + r2

    return R, rt

def reset(sx0, sy0):
    os.chdir(f'../{SIM_DIR}')
    os.system('cp ./restart_base.fld ./restart.fld')
    os.chdir(f'../{DRL_DIR}')

    fact = open('../CFD/trajectory_init.plt', 'w')
    fact.write('%.15f %.15f\n' % (sx0, sy0))
    fact.close()
    
    f = open('../CFD/Q.txt', 'w')
    f.write('%.15f %.15f \n' % (1.0, 1.0))
    f.close()
    os.chdir(f'../{SIM_DIR}')
    os.system(f'nekmpi FRM {NCPU}') #:: interpolate the initial velocity
    os.chdir(f'../{DRL_DIR}')

    data= np.loadtxt('../CFD/trajectory_init.plt')
    kx0=data[2]; ky0=data[3]

    s = [sx0,sy0,kx0*100,ky0*100,kx0*100/0.2,ky0*100/0.2]
    s = np.array(s)
    return s

def step(Qnow):
    f = open('../CFD/Q.txt', 'w')
    f.write('%.15f %.15f \n' % (Qnow[0], Qnow[1]))
    f.close()
    
    os.chdir(f'../{SIM_DIR}')
    os.system(f'nekmpi FRM {NCPU}')
    os.chdir(f'../{DRL_DIR}')
    
    data= np.loadtxt('../CFD/trajectory_hist_t.dat')
    sx_t = data[-1,0]; sy_t = data[-1,1]
    kx_t = data[-1,2]; ky_t = data[-1,3]
    kx_t1 = data[-2,2]; ky_t1 = data[-2,3]
    ax = (kx_t-kx_t1)/0.2; ay = (ky_t-ky_t1)/0.2
    f = open('../CFD/trajectory_init.plt', 'w')
    f.write('%.15f %.15f \n' % (sx_t, sy_t))
    f.close()
    
    os.chdir(f'../{SIM_DIR}')
    os.system('cp ./FRM0.f00001 ./restart.fld')
    os.chdir(f'../{DRL_DIR}')

    s_t = [sx_t,sy_t,kx_t*100,ky_t*100,ax*100,ay*100]
    s_t = np.array(s_t)
    return s_t

def copy_saved_models(episode_number,previous_models_number):
    
    # Save intermediate models
    if (episode_number > 1) and (episode_number % 10 == 0):
        os.system('cp -r saved_models saved_models{0}'.format(
            str(previous_models_number + episode_number // 10)))


def output_data(episode_number, step, action, reward, state_t, s0, rt):
    name = "output.plt"
    state_file = "state.plt"
    if (not os.path.exists("saved_models")):
        os.mkdir("saved_models")
    if (not os.path.exists("saved_models/" + name)):
        with open("saved_models/" + name, "w") as csv_file:
            spam_writer = csv.writer(csv_file, delimiter=",", lineterminator="\n")
            spam_writer.writerow(['Episode', 'Step', 'Action1', 'Action2', 'Reward', 'rt', 'sx', 'sy', 'kx', 'ky', 'ax', 'ay'])
            spam_writer.writerow([episode_number, step, action[0], action[1], reward, rt, state_t[0], state_t[1], state_t[2], state_t[3], state_t[4], state_t[5]])
        with open("saved_models/" + state_file, "w") as csv_file:
            spam_writer = csv.writer(csv_file, delimiter=",", lineterminator="\n")
            spam_writer.writerow([s0,state_t])
    else:
        with open("saved_models/" + name, "a") as csv_file:
            spam_writer = csv.writer(csv_file, delimiter=",", lineterminator="\n")
            spam_writer.writerow([episode_number, step, action[0], action[1], reward, rt, state_t[0], state_t[1], state_t[2], state_t[3], state_t[4], state_t[5]])
        with open("saved_models/" + state_file, "a") as csv_file:
            spam_writer = csv.writer(csv_file, delimiter=",", lineterminator="\n")
            spam_writer.writerow([s0,state_t])

def output_hist(episode_number, rt, all_ep_r, ep_r, disc_r, v_s_, r_end, j):
    name = "train_hist.plt"
    if (not os.path.exists("saved_models")):
        os.mkdir("saved_models")
    if (not os.path.exists("saved_models/" + name)):
        with open("saved_models/" + name, "w") as csv_file:
            spam_writer = csv.writer(csv_file, delimiter=",", lineterminator="\n")
            spam_writer.writerow(['Episode', 'rt', 'avg_ep_r', 'ep_r', 'disc_r', 'v_s_', 'r_end', 'steps'])
            spam_writer.writerow([episode_number, rt, all_ep_r, ep_r, disc_r, v_s_, r_end, j])
    else:
        with open("saved_models/" + name, "a") as csv_file:
            spam_writer = csv.writer(csv_file, delimiter=",", lineterminator="\n")
            spam_writer.writerow([episode_number, rt, all_ep_r, ep_r, disc_r, v_s_, r_end, j])


#------------------------------------------------------------------------------------
#--- Training
#------------------------------------------------------------------------------------

#:: How many cores to run
NCPU = 20
SIM_DIR = 'CFD'
DRL_DIR = 'r005_60'

#:: Check if there are previous models
previous_models_number = 0
for ic in range(200, 0, -1):
    if os.path.isfile('./saved_models' + str(ic) + '/PPO_model.pth'):
        previous_models_number = ic
        break

#:: Define the PPO agent
eta = 1.5 # action limit
ppo = PPO(6, 2, [300,300], eta) # ppo(state dimension, action dimension, network size, clipped limit)
if (not os.path.exists("saved_models")):
    os.mkdir("saved_models")
else:
    ppo.restore()

#:: Define the initial position
h0 = 0.05 * np.sqrt(2)
theta = 60
x_ic = -h0 * np.cos(np.deg2rad(theta))
y_ic = h0 * np.sin(np.deg2rad(theta))
h_threshold = 0.0025

#:: Parameters
max_episode = 1000
max_step = 30
BATCH = max_step
GAMMA = 0.98
all_ep_r = []
k = previous_models_number

for i in range(max_episode):
    s = reset(x_ic, y_ic)
    NEAR = False
    STOP = False
    print(f'>>> The shape of s: {s.shape}')
    buffer_s, buffer_a, buffer_r = [], [], []
    ep_r = 0

    for j in range(max_step):

        a = ppo.choose_action(s)
        s_ = step(a)
        r, rt = compute_reward(s, s_)

        if rt < h_threshold:
            STOP = True
            r += 2

        output_data(i+1+k*10, j+1, a, r, s_, s, rt)
        buffer_s.append(s)
        buffer_a.append(a)
        buffer_r.append(r)
        s = s_
        ep_r += r

        if (j + 1) % BATCH == 0 or j == max_step - 1 or STOP:
            v_s_ = ppo.get_v(s_)
            temp1 = v_s_
            temp2 = buffer_r[-1]
            discounted_r = []
            for r in buffer_r[::-1]:
                v_s_ = r + GAMMA * v_s_
                discounted_r.append(v_s_)

            discounted_r.reverse()

            # bs, ba, br = np.vstack(buffer_s), np.vstack(buffer_a), np.array(discounted_r)[:, np.newaxis]
            bs, ba, br = np.vstack(buffer_s), np.vstack(buffer_a), (np.array(discounted_r)).reshape(-1,1)
            buffer_s, buffer_a, buffer_r = [], [], []
            ppo.update(bs, ba, br)

            if STOP:
                break

    if i == 0:
        all_ep_r.append(ep_r)
    else:
        all_ep_r.append(all_ep_r[-1]*0.9 + ep_r*0.1)

    output_hist(i+1+k*10, rt, all_ep_r[-1], ep_r, discounted_r[0], temp1, temp2, j+1)

    ppo.save()
    copy_saved_models(i+1,previous_models_number)

