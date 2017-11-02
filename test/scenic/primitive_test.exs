#
#  Created by Boyd Multerer on 5/7/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.PrimitiveTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Primitive
  alias Scenic.Primitive.Group

#  import IEx

  defmodule TestStyle do
    def get(_), do: :test_style_getter
  end


  @tx_pin             {10,11}
  @tx_rotate          0.1
  @transforms         %{pin: @tx_pin, rotate: @tx_rotate}

  @styles             %{color: {:red, :yellow}, line_width: 10}

  @parent_uid         123
  @type_module        Group
  @event_filter       {:module, :action}
  @tag_list           ["tag0", :tag1]
  @state              {:app,:state}
  @data               [1,2,3,4,5]


  @primitive %Primitive{
    module:       @type_module,
    uid:          nil,
    parent_uid:   @parent_uid,
    data:         @data,
    id:           :test_id,
    tags:         @tag_list,
    event_filter: @event_filter,
    state:        @state,
    transforms:   @transforms,
    styles:       @styles,
  }


  #============================================================================
  # build( data, module, opts \\ [] )

  test "basic primitive build works" do
    assert Primitive.build(Group, @data) == %{
      __struct__: Primitive, module: Group, uid: nil, parent_uid: -1, data: @data
    }
  end

  test "build sets the optional event handler" do
    assert Primitive.build(Group, @data, event_filter: @event_filter) == %{
      __struct__: Primitive, module: Group, uid: nil, parent_uid: -1, data: @data,
      event_filter: @event_filter
    }
  end

  test "build sets the optional tag list" do
    assert Primitive.build(Group, @data, tags: [:one, "two"]) == %{
      __struct__: Primitive, module: Group, uid: nil, parent_uid: -1, data: @data,
      tags: [:one, "two"]
    }
  end

  test "build adds transform options" do
    assert Primitive.build(Group, @data, pin: {10,11}, rotate: 0.1) == %{
      __struct__: Primitive, module: Group, uid: nil, parent_uid: -1, data: @data,
      transforms: @transforms
    }
  end


  test "build adds the style opts" do
    assert Primitive.build(Group, @data, color: {:red, :yellow}, line_width: 10) == %{
      __struct__: Primitive, module: Group, uid: nil, parent_uid: -1, data: @data,
      styles: @styles
    }
  end

  test "build sets the optional state" do
    assert Primitive.build(Group, @data, state: @state) == %{
      __struct__: Primitive, module: Group, uid: nil, parent_uid: -1, data: @data,
      state: @state
    }
  end

  test "build sets the optional id" do
    assert Primitive.build(Group, @data, id: :test_id) == %{
      __struct__: Primitive, module: Group, uid: nil, parent_uid: -1, data: @data,
      id: :test_id
    }
  end

  test "build raises on bad tx" do
    assert_raise Primitive.Transform.FormatError, fn ->
      Primitive.build(Group, @data, rotate: :invalid)
    end
  end

  test "build raises on bad style" do
    assert_raise Primitive.Style.FormatError, fn ->
      Primitive.build(Group, @data, color: :invalid)
    end
  end

  #============================================================================
  # structure

  #--------------------------------------------------------
  # module

  test "get_module returns the type module" do
    assert Primitive.get_module(@primitive) == @type_module
  end

  #--------------------------------------------------------
  # uid

  test "get_uid and do_put_uid manipulate the internal uid" do
    assert Primitive.put_uid(@primitive, 987) |> Primitive.get_uid() == 987
  end

  #--------------------------------------------------------
  # the parent group uid in the graph
  
  test "get_parent_uid returns the uid of the parent." do
    assert Primitive.get_parent_uid(@primitive) == @parent_uid
  end

  test "put_parent_uid sets a parent uid into place" do
    assert Primitive.put_parent_uid(@primitive, 987) |> Primitive.get_parent_uid() == 987
  end

  #--------------------------------------------------------
  # id

  test "get_id returns the internal id." do
    assert Primitive.get_id(@primitive) == :test_id
  end

  test "do_put_id sets the internal id" do
    assert Primitive.put_id(@primitive, :other) |> Primitive.get_id() == :other
  end

  #--------------------------------------------------------
  # searchable tags - can be strings or atoms or integers

  test "get_tags returns the tags" do
    assert Primitive.get_tags(@primitive) == @tag_list
  end

  test "put_tags sets the tag list" do
    tags = ["new", :list, 123]
    primitive = Primitive.put_tags(@primitive, tags)
    assert Primitive.get_tags(primitive) == tags
  end

  test "has_tag? returns true if the tag is in the tag list" do
    assert Primitive.has_tag?(@primitive, "tag0") == true
    assert Primitive.has_tag?(@primitive, :tag1) == true
  end

  test "has_tag? returns false if the tag is not the tag list" do
    assert Primitive.has_tag?(@primitive, "missing") == false
    assert Primitive.has_tag?(@primitive, :missing) == false
  end

  test "put_tag adds a tag to the front of the tag list" do
    assert Primitive.put_tag(@primitive, "new") |> Primitive.get_tags() == ["new" | @tag_list]
    assert Primitive.put_tag(@primitive, :new)  |> Primitive.get_tags() == [:new | @tag_list]
    assert Primitive.put_tag(@primitive, 123)   |> Primitive.get_tags() == [123 | @tag_list]
  end

  test "put_tag does nothing if the tag is already in the list" do
    assert Primitive.put_tag(@primitive, "tag0") |> Primitive.get_tags()  == @tag_list
    assert Primitive.put_tag(@primitive, :tag1)  |> Primitive.get_tags()  == @tag_list
  end

  test "delete_tag deletes a tag from the tag list" do
    assert (Primitive.delete_tag(@primitive, "tag0") |> Primitive.get_tags()) == [:tag1]
    assert (Primitive.delete_tag(@primitive, :tag1)  |> Primitive.get_tags()) == ["tag0"]
  end


  #--------------------------------------------------------
  # the handler for input events

  test "get_event_filter returns the event handler." do
    assert Primitive.get_event_filter(@primitive) == @event_filter
  end

  test "put_event_filter sets the event handler as {module,action}" do
    p = Primitive.put_event_filter(@primitive, { :mod, :act } )
    assert Primitive.get_event_filter(p) == { :mod, :act }
  end

  test "put_event_filter sets the event handler to a function" do
    p = Primitive.put_event_filter(@primitive, fn(_a,_b,_c,_d) -> nil end)
    assert is_function(Primitive.get_event_filter(p), 4)
  end

  test "put_event_filter sets the event handler to nil" do
    p = Primitive.put_event_filter(@primitive, { :mod, :act } )
    assert Primitive.get_event_filter(p) == { :mod, :act }
    p = Primitive.put_event_filter(@primitive, nil )
    assert Primitive.get_event_filter(p) == nil
  end

  #--------------------------------------------------------
  test "delete_event_filter sets the event filter to nil" do
    p = Primitive.put_event_filter(@primitive, { :mod, :act } )
    assert Primitive.get_event_filter(p) == { :mod, :act }
    p = Primitive.delete_event_filter( @primitive )
    assert Primitive.get_event_filter(p) == nil
  end

  #============================================================================
  # transform field

  test "get_transforms returns the transforms" do
    assert Primitive.get_transforms(@primitive) == @transforms
  end

  test "get_transform returns the transform" do
    assert Primitive.get_transform(@primitive, :pin) == @tx_pin
  end

  test "put_transform sets the transform" do
    p = Primitive.put_transform(@primitive, :pin, {987,654})
    assert Primitive.get_transform(p, :pin) == {987,654}
  end

  test "put_transform deletes the transform type if setting to nil" do
    p = Primitive.put_transform(@primitive, :pin, nil)
    assert Primitive.get_transforms(p) == %{ rotate: @tx_rotate }
  end

  test "put_transform sets the transform to nil" do
    p = Primitive.put_transforms(@primitive, nil)
    assert Map.get(p, :transforms) == nil
  end

  #--------------------------------------------------------
  # local matrix
#  test "get_matrix returns the final matrix" do
#    local_matrix = @primitive
#      |> Primitive.get_transform()
#      |> Transform.get_local()
#    assert Primitive.get_local_matrix(@primitive) == local_matrix
#  end
#
#  #--------------------------------------------------------
#  # local matrix
#  test "calculate_inverse_matrix calculates and returns the inverse final matrix" do
#    inverse_matrix = @primitive
#      |> Primitive.get_transform()
#      |> Transform.get_local()
#      |> MatrixBin.invert()
#    assert Primitive.calculate_inverse_matrix(@primitive) == inverse_matrix
#  end


  #============================================================================
  # style field

  #--------------------------------------------------------
  # styles

  test "get_styles returns the transform list" do
    assert Primitive.get_styles(@primitive) == @styles
  end

  test "get_style returns a style by key" do
    assert Primitive.get_style(@primitive, :color) == {:red, :yellow}
  end

  test "get_style returns nil if missing by default" do
    assert Primitive.get_style(@primitive, :missing) == nil
  end

  test "get_style returns default if missing" do
    assert Primitive.get_style(@primitive, :missing, "default") == "default"
  end

  test "put_style adds to the head of the style list" do
    p = Primitive.put_style(@primitive, :color, :khaki )
    assert Primitive.get_styles(p) == %{color: :khaki, line_width: 10}
  end

  test "put_style replaces a style in the style list" do
    p = @primitive
      |> Primitive.put_style( :color, :khaki )
      |> Primitive.put_style( :color, :cornsilk )
    assert Primitive.get_styles(p) == %{color: :cornsilk, line_width: 10}
  end

  test "put_style a list of styles" do
    new_styles = %{line_width: 4, color: :magenta}
    p = Primitive.put_style(@primitive, [line_width: 4, color: :magenta] )
    assert Primitive.get_styles(p) == new_styles
  end

  test "drop_style removes a style in the style list" do
    assert Primitive.drop_style(@primitive, :color ) |> Primitive.get_styles() == %{line_width: 10}
  end


  #============================================================================
  # data field

  #--------------------------------------------------------
  # compiled primitive-specific data

  test "get_data returns the primitive-specific compiled data" do
    assert Primitive.get(@primitive) == @data
  end

  test "put_data replaces the primitive-specific compiled data" do
    new_data = <<1,2,3,4,5,6,7,8,9,10>>
    p = Primitive.put(@primitive, new_data )
    assert Primitive.get(p) == new_data
  end

  #--------------------------------------------------------
  # app controlled state

  test "get_state gets the application state" do
    assert Primitive.get_state(@primitive) == @state
  end

  test "put_state replaces the application state" do
    p = Primitive.put_state(@primitive, {:def, 123})
    assert Primitive.get_state(p) == {:def, 123}
  end

  #============================================================================




end

