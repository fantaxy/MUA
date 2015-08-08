platform :ios, '8.0'

link_with 'Kmoji-objc', 'Kmoji-keyboard'

def shared_pods
    pod 'OpenShare', '~> 0.0'
    pod 'FIR.im', '~> 1.3.0'
end


target :'Kmoji-objc' do
    shared_pods
    pod 'AFNetworking'
    pod 'JSONKit'
end
target :'Kmoji-keyboard' do
    shared_pods
end
