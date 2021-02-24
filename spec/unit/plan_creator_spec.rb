# frozen_string_literal: true

require 'spec_helper'
require 'bolt/plan_creator'
require 'bolt_spec/project'

describe Bolt::PlanCreator do
  include BoltSpec::Project

  let(:project)   { @project }
  let(:plan_name) { 'project' }
  let(:outputter) { double('outputter', print_message: true) }

  around :each do |example|
    with_project(plan_name) do |project|
      @project = project
      example.run
    end
  end

  context "#validate_input" do
    it 'errors without a named project' do
      allow(project).to receive(:name).and_return(nil)
      expect { subject.validate_input(project, plan_name) }.to raise_error(
        Bolt::Error,
        /Project directory '.*' is not a named project/
      )
    end

    it 'errors when the plan name is invalid' do
      %w[Foo foo-bar foo:: foo::Bar foo::1bar ::foo].each do |plan_name|
        expect { subject.validate_input(project, plan_name) }.to raise_error(
          Bolt::ValidationError,
          /Invalid plan name '#{plan_name}'/
        )
      end
    end

    it 'errors if the first name segment is not the project name' do
      expect { subject.validate_input(project, 'plan') }.to raise_error(
        Bolt::ValidationError,
        /First segment of plan name 'plan' must match project name/
      )
    end

    %w[pp yaml].each do |ext|
      it "errors if there is an existing #{ext} plan with the same name" do
        plan_path = File.join(project.path, 'plans', "init.#{ext}")
        FileUtils.mkdir(File.dirname(plan_path))
        FileUtils.touch(plan_path)

        expect { subject.validate_input(project, plan_name) }.to raise_error(
          Bolt::Error,
          /A plan with the name '#{plan_name}' already exists/
        )
      end
    end
  end

  context "#create_plan" do
    it "creates a missing 'plans' directory" do
      expect(Dir.exist?(project.plans_path)).to eq(false)
      subject.create_plan(project.plans_path, plan_name, outputter, nil)
      expect(Dir.exist?(project.plans_path)).to eq(true)
    end

    it 'creates a missing directory structure' do
      plan_name = "#{project.name}::foo::bar"
      expect(Dir.exist?(project.plans_path + 'foo')).to eq(false)
      subject.create_plan(project.plans_path, plan_name, outputter, nil)
      expect(Dir.exist?(project.plans_path + 'foo')).to eq(true)
    end

    it 'catches existing file errors when creating directories' do
      plan_name = "#{project.name}::foo::bar"
      FileUtils.mkdir(project.plans_path)
      FileUtils.touch(project.plans_path + 'foo')

      expect { subject.create_plan(project.plans_path, plan_name, outputter, nil) }
        .to raise_error(Bolt::Error, /unable to create plan directory/)
    end

    it "creates an 'init' plan when the plan name matches the project name" do
      subject.create_plan(project.plans_path, plan_name, outputter, nil)
      expect(File.exist?(project.plans_path + 'init.yaml')).to eq(true)
    end

    it 'creates a yaml plan by default' do
      plan_name = "#{project.name}::foo"

      subject.create_plan(project.plans_path, plan_name, outputter, nil)
      expect(File.read(project.plans_path + 'foo.yaml'))
        .to eq(subject.yaml_plan(plan_name))
    end

    it 'creates a puppet plan when the flag is provided' do
      plan_name = "#{project.name}::foo"

      subject.create_plan(project.plans_path, plan_name, outputter, true)
      expect(File.read(project.plans_path + 'foo.pp'))
        .to eq(subject.puppet_plan(plan_name))
    end

    it 'outputs the path to the plan and other helpful information' do
      if Bolt::Util.powershell?
        show_command = 'Get-BoltPlan -Name '
        run_command  = 'Invoke-BoltPlan -Name '
      else
        show_command = 'bolt plan show'
        run_command  = 'bolt plan run'
      end

      allow(outputter).to receive(:print_message) do |output|
        expect(output).to match(
          /Created plan '#{plan_name}' at '#{project.plans_path + 'init.yaml'}'/
        )
        expect(output).to match(
          /#{show_command} #{plan_name}/
        )
        expect(output).to match(
          /#{run_command} #{plan_name}/
        )
      end
      subject.create_plan(project.plans_path, plan_name, outputter, nil)
    end
  end
end
