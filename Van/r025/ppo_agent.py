import numpy as np
import torch
import torch.nn as nn
import matplotlib.pyplot as plt
import torch.nn.functional as F

from torch.distributions import Normal


A_UPDATE_STEPS = 10
C_UPDATE_STEPS = 10
METHOD = [
    dict(name='kl_pen', kl_target=0.01, lam=0.5),  # KL penalty # 0.5
    dict(name='clip', epsilon=0.1)  # clip
][1]  # choose the method for optimization
# METHOD[0]: Adaptive KL penalty Coefficient
# METHOD[1]: Clipped Surrogate Objective


class Actor(nn.Module):
    def __init__(self, obs_dim, act_dim, layers_size, act_lim):
        super(Actor, self).__init__()
        self.act_lim = act_lim
        self.net = nn.Sequential( 
                      nn.Linear(obs_dim, layers_size[0], bias=True), 
                      nn.ReLU(),
                      nn.Linear(layers_size[0], layers_size[1], bias=True),
                      nn.ReLU()
                    )
        
        self.mu = nn.Sequential(
                  nn.Linear(layers_size[1], act_dim, bias=True), 
                  nn.Tanh()
                  )

        self.sigma = nn.Sequential(
                     nn.Linear(layers_size[1], act_dim, bias=True), 
                     nn.Softplus()
                     )

    def forward(self, x):
        y = self.net(x)
        mu = self.act_lim * self.mu(y)
        sigma = self.sigma(y)
        return mu, sigma


class Critic(nn.Module):
    def __init__(self, obs_dim, layers_size):
        super(Critic, self).__init__()
        self.net = nn.Sequential(
                   nn.Linear(obs_dim, layers_size[0], bias=True),
                   nn.ReLU(),
                   nn.Linear(layers_size[0], layers_size[1], bias=True),
                   nn.ReLU(),
                   nn.Linear(layers_size[1], 1, bias=True),
                   )

    def forward(self, x):
        return self.net(x)


class PPO(object):

    def __init__(self, obs_dim, act_dim, layers_size, act_lim, actor_lr=0.0001, critic_lr=0.0002, max_grad_norm=0.5):
        self.actor_lr = actor_lr
        self.critic_lr = critic_lr
        self.actor_old = Actor(obs_dim, act_dim, layers_size, act_lim)
        self.actor = Actor(obs_dim, act_dim, layers_size, act_lim)
        self.critic = Critic(obs_dim, layers_size)
        self.actor_optimizer = torch.optim.Adam(params=self.actor.parameters(), lr=self.actor_lr)
        self.critic_optimizer = torch.optim.Adam(params=self.critic.parameters(), lr=self.critic_lr)
        self.max_grad_norm = max_grad_norm 
        self.act_lim = act_lim
        # summary(self.actor)

    def update(self, s, a, r):
        self.actor_old.load_state_dict(self.actor.state_dict())
        state = torch.FloatTensor(s)
        action = torch.FloatTensor(a)
        discounted_r = torch.FloatTensor(r)


        mu_old, sigma_old = self.actor_old(state)
        dist_old = Normal(mu_old, sigma_old)
        old_action_log_prob = dist_old.log_prob(action).detach()

        target_v = discounted_r

        advantage = (target_v - self.critic(state)).detach()
        # advantage = (advantage - advantage.mean()) / (advantage.std()+1e-6)  # sometimes helpful by movan

        #>> "update actor net"
        if METHOD['name'] == 'kl_pen':
            for _ in range(A_UPDATE_STEPS):
                # compute new_action_log_prob
                mu, sigma = self.actor(state)
                dist = Normal(mu, sigma)
                new_action_log_prob = dist.log_prob(action) 

                new_action_prob = torch.exp(new_action_log_prob)
                old_action_prob = torch.exp(old_action_log_prob)

                #>> "Compute the KL divergence" 
                kl = nn.KLDivLoss()(old_action_prob, new_action_prob)
                #>> "Compute the loss"
                ratio = new_action_prob / old_action_prob
                # ratio = torch.exp(new_action_log_prob - old_action_log_prob)
                actor_loss = -torch.mean(ratio * advantage - METHOD['lam'] * kl)

                self.actor_optimizer.zero_grad()
                actor_loss.backward()
                # nn.utils.clip_grad_norm_(self.actor.parameters(), self.max_grad_norm)
                self.actor_optimizer.step()
                if kl > 4*METHOD['kl_target']:
                    # this in google's paper
                    break
            if kl < METHOD['kl_target'] / 1.5:
                METHOD['lam'] /= 2
            elif kl > METHOD['kl_target'] * 1.5:
                METHOD['lam'] *= 2
            METHOD['lam'] = np.clip(METHOD['lam'], 1e-4, 10)
        else:
            # clipping method, find this is better (OpenAI's paper)
            # update actor net
            for _ in range(A_UPDATE_STEPS):
                ## update step as follows:
                # compute new_action_log_prob
                mu, sigma = self.actor(state)
                dist_n = Normal(mu, sigma)
                new_action_log_prob = dist_n.log_prob(action)

                ratio = torch.exp(new_action_log_prob - old_action_log_prob)

                # L1 = ratio * td_error, td_error or advatange
                L1 = ratio * advantage

                L2 = torch.clamp(ratio, 1-METHOD['epsilon'], 1+METHOD['epsilon']) * advantage

                actor_loss = -torch.min(L1, L2).mean()

                self.actor_optimizer.zero_grad()
                actor_loss.backward()
                #>> """clip grad norm to eliminate grad explosion"""
                # nn.utils.clip_grad_norm_(self.actor.parameters(), self.max_grad_norm)
                self.actor_optimizer.step()

        # update critic net
        for _ in range(C_UPDATE_STEPS):
            critic_loss = nn.MSELoss(reduction='mean')(self.critic(state), target_v)
            self.critic_optimizer.zero_grad()
            critic_loss.backward()
            #>> "clip grad norm to eliminate grad explosion"
            # nn.utils.clip_grad_norm_(self.critic.parameters(), self.max_grad_norm)
            self.critic_optimizer.step()

    def choose_action(self, s):
        s = torch.FloatTensor(s)
        with torch.no_grad():
            mu, sigma = self.actor(s)
        dist = Normal(mu, sigma)
        action = dist.sample()
        # action = action.clamp(-self.act_lim, self.act_lim)
        action = action.clamp(-2, 2)
        return np.squeeze(action.numpy())

    def get_v(self, s):
        s = torch.FloatTensor(s)
        with torch.no_grad():
            value = self.critic(s)
        return value.item()
    
    def save(self):
        torch.save({
        'actor_state_dict': self.actor.state_dict(),
        'critic_state_dict': self.critic.state_dict(),
        'actor_optimizer': self.actor_optimizer.state_dict(),
        'critic_optimizer': self.critic_optimizer.state_dict(),
        }, './saved_models/PPO_model.pth')

    
    def restore(self,model_id=0):
        if model_id == 0:
            checkpoint = torch.load('./saved_models/PPO_model.pth')
        else:
            checkpoint = torch.load(f'./saved_models{model_id}/PPO_model.pth')
        self.actor.load_state_dict(checkpoint['actor_state_dict'])
        self.critic.load_state_dict(checkpoint['critic_state_dict'])

