%  MATLAB Source Codes for the book "Cooperative Decision and Planning for
%  Connected and Automated Vehicles" published by Mechanical Industry Press
%  in 2020.
% ��������������Эͬ������滮�������鼮���״���
%  Copyright (C) 2020 Bai Li
%  2020.02.03
% ==============================================================================
%  �ڶ���. X-Y-T��άA�������㷨�켣���ߡ���ֵ������ſ����������켣�Ż�
% ==============================================================================
%  ��ע��
%  1. �����֧������AMPL
%  2. ���ڸò��ִ�����о��ɹ����������²ο����ף�
%  a) B. Li, and Z. Shao, ��A unified motion planning method for
%     parking an autonomous vehicle in the presence of irregularly placed
%     obstacles,�� Knowledge-Based Systems, vol. 86, pp. 11�C20, 2015.
%  b) B. Li, K. Wang, and Z. Shao, ��Time-optimal maneuver planning in
%     automatic parallel parking using a simultaneous dynamic optimization
%     approach,�� IEEE Transactions on Intelligent Transportation Systems, vol.
%     17, no. 11, pp. 3263�C3274, 2016.
%  3. ���ڳ�ʼ������һ�㣬��ֵ�������ʧ�ܵĿ����Խϴ�.
% ==============================================================================
clear all
close all
clc

% % ��������
global vehicle_geometrics_ % �����������γߴ�
vehicle_geometrics_.vehicle_wheelbase = 2.8;
vehicle_geometrics_.vehicle_front_hang = 0.96;
vehicle_geometrics_.vehicle_rear_hang = 0.929;
vehicle_geometrics_.vehicle_width = 1.942;
global vehicle_kinematics_ % �����˶���������
vehicle_kinematics_.vehicle_v_max = 2.5;
vehicle_kinematics_.vehicle_a_max = 0.5;
vehicle_kinematics_.vehicle_phy_max = 0.7;
vehicle_kinematics_.vehicle_w_max = 0.5;
vehicle_kinematics_.vehicle_kappa_max = tan(vehicle_kinematics_.vehicle_phy_max) / vehicle_geometrics_.vehicle_wheelbase;
vehicle_kinematics_.vehicle_turning_radius_min = 1 / vehicle_kinematics_.vehicle_kappa_max;
global environment_scale_ % �������ڻ�����Χ
environment_scale_.environment_x_min = -20;
environment_scale_.environment_x_max = 20;
environment_scale_.environment_y_min = -20;
environment_scale_.environment_y_max = 20;
environment_scale_.x_scale = environment_scale_.environment_x_max - environment_scale_.environment_x_min;
environment_scale_.y_scale = environment_scale_.environment_y_max - environment_scale_.environment_y_min;
% % ����X-Y-Tͼ������A���㷨�漰�Ĳ���
global xyt_graph_search_
xyt_graph_search_.max_t = 40;
xyt_graph_search_.num_nodes_t = 121;
xyt_graph_search_.resolution_t = xyt_graph_search_.max_t / (xyt_graph_search_.num_nodes_t - 1);
xyt_graph_search_.resolution_x = xyt_graph_search_.resolution_t * vehicle_kinematics_.vehicle_v_max / (3 * 1.414);
xyt_graph_search_.resolution_y = xyt_graph_search_.resolution_x;
xyt_graph_search_.num_nodes_x = ceil(environment_scale_.x_scale / xyt_graph_search_.resolution_x);
xyt_graph_search_.num_nodes_y = ceil(environment_scale_.y_scale / xyt_graph_search_.resolution_y);
xyt_graph_search_.multiplier_H_for_A_star = 1.0;
xyt_graph_search_.weight_for_time = 2.0;
xyt_graph_search_.max_iter = 10000;
% % ����ȶ������Լ���ֹ�ϰ���ֲ����
global vehicle_TPBV_ obstacle_vertexes_ dynamic_obs
load TaskSetup.mat
dynamic_obs = GenerateDynamicObstacles();
% % X-Y-Tͼ����
start_ind = ConvertConfigToIndex(vehicle_TPBV_.x0, vehicle_TPBV_.y0, 0);
goal_ind = ConvertConfigToIndex(vehicle_TPBV_.xtf, vehicle_TPBV_.ytf, xyt_graph_search_.max_t);
tic
[x, y, theta, fitness] = SearchTrajectoryInXYTGraph(start_ind, goal_ind);
disp(['CPU time elapsed for A* search: ',num2str(toc), ' sec.'])

% % �켣�滮
[x, y, theta, v, a, phy, w] = FormInitialGuess(x, y, theta);
WriteInitialGuessForNLP(x, y, theta, v, a, phy, w);
WriteObstacleSetupsForNLP();
WriteBoundaryValues();
!ampl rr.run
% % �켣�滮���չʾ
load opti_flag.txt
if (opti_flag)
    dsa();
    asd();
end