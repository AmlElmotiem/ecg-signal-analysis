function fig = plot_hrv(hrv)
%PLOT_HRV Poincare plot of successive RR intervals (RR(n) vs RR(n+1)).
%   A tight, elongated cluster along the diagonal means low
%   beat-to-beat variability; a wider, more circular spread means
%   higher short-term variability (higher RMSSD).
    rr = hrv.rr_intervals_ms;
    fig = figure('Color', 'w');
    scatter(rr(1:end - 1), rr(2:end), 30, 'filled', 'MarkerFaceAlpha', 0.6);
    hold on;
    lims = [min(rr) * 0.9, max(rr) * 1.1];
    plot(lims, lims, 'k--');
    xlim(lims);
    ylim(lims);
    axis square;
    xlabel('RR_n (ms)');
    ylabel('RR_{n+1} (ms)');
    title(sprintf('Poincar\x00e9 Plot (SDNN=%.1fms, RMSSD=%.1fms)', hrv.sdnn_ms, hrv.rmssd_ms));
    grid on;
end
