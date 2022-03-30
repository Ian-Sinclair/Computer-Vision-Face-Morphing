clear
  
Raw_Image_Hillary = imread("hillary_clinton.jpg");
Raw_Image_Ted = imread("ted_cruz.jpg");



Feature_Points_Hillary_Text = fopen("hillary_clinton.txt");

Feature_Points_Ted_Text = fopen("ted_cruz.txt");

Feature_Points_Hillary = fscanf(Feature_Points_Hillary_Text, '%d', [2 100]);

Feature_Points_Ted = fscanf(Feature_Points_Ted_Text, '%d', [2 76]);


Delaunay_Triangulation_File = fopen("tri.txt");

Delaunay_Triangulation = fscanf(Delaunay_Triangulation_File, '%d', [3, 142]);





Hillary_Triangulation = {};

for triangle = Delaunay_Triangulation 
    vertex1 = [ Feature_Points_Hillary( 1 , triangle(1)+1 ), 
        Feature_Points_Hillary( 1 , triangle(2)+1 ), 
        Feature_Points_Hillary( 1 , triangle(3) +1 )];
    vertex2 = [ Feature_Points_Hillary( 2 , triangle(1)+ 1 ), 
        Feature_Points_Hillary( 2 , triangle(2) + 1 ), 
        Feature_Points_Hillary( 2 , triangle(3) + 1 )
        ];
    Hillary_Triangulation{1,end+1} = vertex1;
    Hillary_Triangulation{2,end} = vertex2;
end


Ted_Triangulation = {};

for triangle = Delaunay_Triangulation 
    vertex1 = [ Feature_Points_Ted( 1 , triangle(1)+1 ), 
        Feature_Points_Ted( 1 , triangle(2)+1 ), 
        Feature_Points_Ted( 1 , triangle(3) +1 )];
    vertex2 = [ Feature_Points_Ted( 2 , triangle(1)+ 1 ), 
        Feature_Points_Ted( 2 , triangle(2) + 1 ), 
        Feature_Points_Ted( 2 , triangle(3) + 1 )
        ];
    Ted_Triangulation{1,end+1} = vertex1;
    Ted_Triangulation{2,end} = vertex2;
end

index = 0;
for alpha = 0:0.1:1

    Morphed_Triangulation = {};

    blendPoint = [];
    hold on
    for i = 1:length(Hillary_Triangulation)
        vertex1 = [ (1-alpha)*Hillary_Triangulation{1,i}(1) + alpha*Ted_Triangulation{1,i}(1),
            (1-alpha)*Hillary_Triangulation{1,i}(2) + alpha*Ted_Triangulation{1,i}(2),
            (1-alpha)*Hillary_Triangulation{1,i}(3) + alpha*Ted_Triangulation{1,i}(3)
            ];
        vertex2 = [ (1-alpha)*Hillary_Triangulation{2,i}(1) + alpha*Ted_Triangulation{2,i}(1),
            (1-alpha)*Hillary_Triangulation{2,i}(2) + alpha*Ted_Triangulation{2,i}(2),
            (1-alpha)*Hillary_Triangulation{2,i}(3) + alpha*Ted_Triangulation{2,i}(3)
            ];
        Morphed_Triangulation{1,end+1} = vertex1;
        Morphed_Triangulation{2,end} = vertex2;
    end


    Affine_Hillary = {};
    Affine_Ted = {};

    for i = 1:length(Hillary_Triangulation)
        moving_points_h = [Hillary_Triangulation{1,i}(1) , Hillary_Triangulation{2,i}(1);
            Hillary_Triangulation{1,i}(2) , Hillary_Triangulation{2,i}(2);
            Hillary_Triangulation{1,i}(3) , Hillary_Triangulation{2,i}(3)];
        
        moving_points_t = [Ted_Triangulation{1,i}(1) , Ted_Triangulation{2,i}(1);
            Ted_Triangulation{1,i}(2) , Ted_Triangulation{2,i}(2);
            Ted_Triangulation{1,i}(3) , Ted_Triangulation{2,i}(3)];
        
        fixed_points = [Morphed_Triangulation{1,i}(1) , Morphed_Triangulation{2,i}(1);
            Morphed_Triangulation{1,i}(2) , Morphed_Triangulation{2,i}(2);
            Morphed_Triangulation{1,i}(3) , Morphed_Triangulation{2,i}(3)];
        
        Affine_Hillary{end+1} = fitgeotrans(moving_points_h, fixed_points, 'affine');
        Affine_Ted{end+1} = fitgeotrans(moving_points_t, fixed_points, 'affine');
    end

    Out_Image = zeros(800,600,3,'uint8');



    bbox_Hillary = {};
    bbox_Ted = {};
    bbox_Target = {};

    for i = 1:length(Morphed_Triangulation)
        bbox_Hillary{end+1} = [min(Hillary_Triangulation{1,i}), min(Hillary_Triangulation{2,i}), max(Hillary_Triangulation{1,i}), max(Hillary_Triangulation{2,i})];
        bbox_Ted{end+1} = [min(Ted_Triangulation{1,i}), min(Ted_Triangulation{2,i}), max(Ted_Triangulation{1,i}), max(Ted_Triangulation{2,i})];
        bbox_Target{end+1} = [min(Morphed_Triangulation{1,i}), min(Morphed_Triangulation{2,i}), max(Morphed_Triangulation{1,i}), max(Morphed_Triangulation{2,i})];
    end


    cropped_images_Hillary = {};
    cropped_images_Ted = {};

    for bbox = bbox_Hillary
        box_width = bbox{1}(3) - bbox{1}(1);
        box_height = bbox{1}(4) - bbox{1}(2);
        cropped_images_Hillary{end+1} = imcrop(Raw_Image_Hillary, [bbox{1}(1), bbox{1}(2), box_height , box_width]);
    end
    for bbox = bbox_Ted
        box_width = bbox{1}(3) - bbox{1}(1);
        box_height = bbox{1}(4) - bbox{1}(2);
        cropped_images_Ted{end+1} = imcrop(Raw_Image_Ted, [bbox{1}(1), bbox{1}(2), box_height ,box_width]);
    end




    warped_images_Hillary = {};
    warped_images_Ted = {};
    for i = 1:length(cropped_images_Ted)
        warped_images_Hillary{end+1} = imwarp(cropped_images_Hillary{i}, Affine_Hillary{i});
        warped_images_Ted{end+1} = imwarp(cropped_images_Ted{i}, Affine_Ted{i});
    end


    Out_Image = zeros(800,600,3,'uint8');

    for i = 1:length(bbox_Target)
        for j = bbox_Target{i}(1):bbox_Target{i}(3)
            for k = bbox_Target{i}(2):bbox_Target{i}(4)
                [IN,ON] = inpolygon(j,k, Morphed_Triangulation{1,i},Morphed_Triangulation{2,i});
                if IN == 1 || ON == 1
                    if j ~= 0 && k ~= 0
                        H_coord = Affine_Hillary{i}.T'^-1*[j;k;1];
                        T_coord = Affine_Ted{i}.T'^-1*[j;k;1];
                        Out_Image(ceil(k),ceil(j),1) = (1-alpha)*Raw_Image_Hillary(ceil(H_coord(2)), ceil(H_coord(1)),1) + alpha*Raw_Image_Ted(ceil(T_coord(2)), ceil(T_coord(1)),1);
                        Out_Image(ceil(k),ceil(j),2) = (1-alpha)*Raw_Image_Hillary(ceil(H_coord(2)), ceil(H_coord(1)),2) + alpha*Raw_Image_Ted(ceil(T_coord(2)), ceil(T_coord(1)),2);
                        Out_Image(ceil(k),ceil(j),3) = (1-alpha)*Raw_Image_Hillary(ceil(H_coord(2)), ceil(H_coord(1)),3) + alpha*Raw_Image_Ted(ceil(T_coord(2)), ceil(T_coord(1)),3);
                    end
                end
                if IN == 1 || ON == 1
                    if j >= 1 && k >= 1
                        H_coord = Affine_Hillary{i}.T'^-1*[j;k;1];
                        T_coord = Affine_Ted{i}.T'^-1*[j;k;1];
                        Out_Image(floor(k),floor(j),1) = (1-alpha)*Raw_Image_Hillary(ceil(H_coord(2)), ceil(H_coord(1)),1) + alpha*Raw_Image_Ted(ceil(T_coord(2)), ceil(T_coord(1)),1);
                        Out_Image(floor(k),floor(j),2) = (1-alpha)*Raw_Image_Hillary(ceil(H_coord(2)), ceil(H_coord(1)),2) + alpha*Raw_Image_Ted(ceil(T_coord(2)), ceil(T_coord(1)),2);
                        Out_Image(floor(k),floor(j),3) = (1-alpha)*Raw_Image_Hillary(ceil(H_coord(2)), ceil(H_coord(1)),3) + alpha*Raw_Image_Ted(ceil(T_coord(2)), ceil(T_coord(1)),3);
                    end
                end
                
                if ON == 1
                    if j >= 1 && k >= 1
                        H_coord = Affine_Hillary{i}.T'^-1*[j;k;1];
                        T_coord = Affine_Ted{i}.T'^-1*[j;k;1];
                        if H_coord(1) >= 1 && H_coord(2) >= 1 && T_coord(1) >= 1 && T_coord(2) >= 1
                            Out_Image(floor(k),floor(j),1) = (1-alpha)*Raw_Image_Hillary(floor(H_coord(2)), floor(H_coord(1)),1) + alpha*Raw_Image_Ted(floor(T_coord(2)), floor(T_coord(1)),1);
                            Out_Image(floor(k),floor(j),2) = (1-alpha)*Raw_Image_Hillary(floor(H_coord(2)), floor(H_coord(1)),2) + alpha*Raw_Image_Ted(floor(T_coord(2)), floor(T_coord(1)),2);
                            Out_Image(floor(k),floor(j),3) = (1-alpha)*Raw_Image_Hillary(floor(H_coord(2)), floor(H_coord(1)),3) + alpha*Raw_Image_Ted(floor(T_coord(2)), floor(T_coord(1)),3);
                            Out_Image(ceil(k),ceil(j),1) = (1-alpha)*Raw_Image_Hillary(floor(H_coord(2)), floor(H_coord(1)),1) + alpha*Raw_Image_Ted(floor(T_coord(2)), floor(T_coord(1)),1);
                            Out_Image(ceil(k),ceil(j),2) = (1-alpha)*Raw_Image_Hillary(floor(H_coord(2)), floor(H_coord(1)),2) + alpha*Raw_Image_Ted(floor(T_coord(2)), floor(T_coord(1)),2);
                            Out_Image(ceil(k),ceil(j),3) = (1-alpha)*Raw_Image_Hillary(floor(H_coord(2)), floor(H_coord(1)),3) + alpha*Raw_Image_Ted(floor(T_coord(2)), floor(T_coord(1)),3);
                            Out_Image(ceil(k),floor(j),1) = (1-alpha)*Raw_Image_Hillary(floor(H_coord(2)), floor(H_coord(1)),1) + alpha*Raw_Image_Ted(floor(T_coord(2)), floor(T_coord(1)),1);
                            Out_Image(ceil(k),floor(j),2) = (1-alpha)*Raw_Image_Hillary(floor(H_coord(2)), floor(H_coord(1)),2) + alpha*Raw_Image_Ted(floor(T_coord(2)), floor(T_coord(1)),2);
                            Out_Image(ceil(k),floor(j),3) = (1-alpha)*Raw_Image_Hillary(floor(H_coord(2)), floor(H_coord(1)),3) + alpha*Raw_Image_Ted(floor(T_coord(2)), floor(T_coord(1)),3);
                            Out_Image(floor(k),ceil(j),1) = (1-alpha)*Raw_Image_Hillary(floor(H_coord(2)), floor(H_coord(1)),1) + alpha*Raw_Image_Ted(floor(T_coord(2)), floor(T_coord(1)),1);
                            Out_Image(floor(k),ceil(j),2) = (1-alpha)*Raw_Image_Hillary(floor(H_coord(2)), floor(H_coord(1)),2) + alpha*Raw_Image_Ted(floor(T_coord(2)), floor(T_coord(1)),2);
                            Out_Image(floor(k),ceil(j),3) = (1-alpha)*Raw_Image_Hillary(floor(H_coord(2)), floor(H_coord(1)),3) + alpha*Raw_Image_Ted(floor(T_coord(2)), floor(T_coord(1)),3);
                        end
                    end
                end
            end
        end
    end


    figure(5)
    imagesc(Out_Image)
    hold on
    for triangle = Morphed_Triangulation
          pgon = polyshape(triangle{1},triangle{2});
          plot(pgon,'FaceColor','blue','FaceAlpha',0.1);  
    end 
    savefig('tempfig.fig')
    figs = openfig('tempfig.fig');

    saveas(figs, append('C:\Users\IanSi\OneDrive\Desktop\Project 3\AAATriangleMorphingImage',string(index),'.jpg'));
%   imwrite(Out_Image,append('C:\Users\IanSi\OneDrive\Desktop\Project 3\AAUpdatedMorphingImage',string(index),'.jpg'));
   index = index + 1;

end

% figure(3)
% imagesc(Out_Image)




