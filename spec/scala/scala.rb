# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with this
# work for additional information regarding copyright ownership.  The ASF
# licenses this file to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
# License for the specific language governing permissions and limitations under
# the License.


require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helpers'))

describe 'scala' do
  # Specific version of Scala required for specs
  required_version = '2.8.0'
  scala_version_str = "2.8.0.final"

  it 'should automatically add the remote scala-tools.org repository' do
    # NOTE: the sandbox environment clears "repositories.remote" so we can't
    #       test for this spec right now.
    #
    # repositories.remote.should include('http://scala-tools.org/repo-releases')
  end

  it "specifications require Scala #{required_version}" do
    Scala.version.should eql(required_version)
  end

  it "should provide the Scala version string" do
    Scala.version_str.should eql(scala_version_str)
  end
end
