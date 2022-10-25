##  Intro

This is a second experiment at creating a viable Drag and Drop (D&D) editable, tree like list view using 100% current SwiftUI components on macOS.

(If interested, the first attempt is over on the branch `list_and_onMove_based`)

In a similar way to the first attempt, the app mocks the UI of a simple Mail program. Where the goal of the app is to allow the user to conveniently navigate and rearrange a potentially large number of hierarchically related items.

To do this the implementation needs to realise:
	
1. The tree as collapsible nodes made up of mail folders and with their content being child items (in order to make efficient use of screen estate).
2. Drag and drop movement of multiple mail and folder items between folders.
2. Auto-expansion and closure of parent folder node (to allow the user to explore for target locations while dragging operations are underway).

*Why*

*So, as of macOS 13 & Xcode 14.1, with the standard shipped `List` component it is possible to have **either**:*

- *A flat, non-hierarchical `List` with multiple items easily movable with in it via the `onMove` modifier.* 

***Or*** 

- *Or a a hierarchical tree `List` but with unmovable items using* 

***But unfortunately not both at the same time**.*

*On macOS, this type of tree view is a convenient and widely used UI paradigm e.g. Finder's View -> 'as List' view. So it would be nice to have something that worked well enough to use in macOS apps without having to resort to `NSViewRepresentable`*

## Building, running and testing

The project's been built using  Xcode 14.1  and runs on macOS 13 

*Aside: Again to the best of knowledge, there is nothing in the code that means it should not work with earlier versions. But it has not been tested on those*

When run it should load some test data and allow the user to:
- Drag and Drop re-arrange selections of Folders and mock mail items anywhere within the tree apart from the root.
- Mark the mock Mail items as read.
- Auto expand closed folders when the user is dragging and close them again after the dragging operation completes.

And  that's it. There is nothing to create new mail or folder items, convert items backward and forwards between Folder and Mail types, change sorting order, allow items to be in multiple parent folders etc. 

Testing - There are no automated tests. Just build and run the app to see what it does.

## Implementation
### Models

The app makes use of the following `ObservableObject` model classes.

- `Items` - models raw business data in the system. Things like: 
	-  its title. 
	-  If the item is a parent (aka folder) item, any children (aka mail items associated with it),  
	
- `AppModel` - Models application level business logic. For instance, in the demo app it provides the canonical list of Items and methods to load the test data.

### Layout
The app uses its own recursive algorithm  to lay out the hierarchical structure using `DisclosureGroup`s.  

It uses `DisclosureGroup` because that component provides api for the programatic expansion and collapse of the group. 

It 

### Drag & Drop
- The dragging process is triggered through the use of the `onDrag` modifier that is attached to both parent folder and child Items. 
- Movement of the dragged items to:
	- Target folders uses the `onDrop` modifier to recognise when the items have been dropped on the target.
	- `onInsert` is used to recognise when items have been dropped inside the contents of a folder.

In both `onDrop` and `onInsert` cases, determination of what items have been moved to the new location use an in-app back-channel to make the process quicker and more robust (at the minor expense of preventing dragging items into or out of the app)

### Folder auto-expansion and collapse
 Folder auto-expansion is triggered after the user hovers with dragged items over a potential target folder item for a short time. 
 
 Once opened, auto-expanded folders are held open for the duration of the dragging operation that triggered their expansion.
 
 When the dragging operation is completed, then after a short delay, any folders that were expanded, are returned to the original state.

## Known missing functionality

### Dragging previews
Ideally the preview displayed when items are being dragged would show the slice of the tree that was being dragged, complete with the any folders in the selection being in the same state as in the main interface i.e. open or closed. 

However, can't do that at the moment because the expanded/collapsed UI state for a folder items is not accessible outside of the views it pertains to. 

To fix, code needs to move to an approach based on dragging `DisplayItems`. (These would be an aggregation of the original Item and the state of the UI rendering it) 

Complication with this, would be that `DisplayItems` would need to be per-window (and not per `AppModel`. As would not want expansion and collapse operation in one window to effect what interactions in another.
	
## Weirdness

 
### Previous vs this version comparisons

| Functional  | Previous version (`list_and_onMove_based`) |  Current  (`main`)|
|:--          |:--                            |:--       |
| **Functional** | | |
| Item move | ✅ | ✅ |
| Folder movement | ✅ | ✅ |
| Folder auto expand | ❌ | ✅  |
| Folder auto collapse | ❌ | ✅ |
| **Implementation** | | |
| Custom indented `List` with `onMove`  | ✅ | |
| `List` with `DisclosureGroup`, `onDrag`, `onDrop` and `onInsert` | | ✅ |

