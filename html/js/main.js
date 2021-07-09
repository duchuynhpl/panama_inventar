var state = '', selected = 0, itemData = {}, equipped = {};
var isSlotAnimation = false, canChange = true
const resourceName = 'panama_inventar';

window.addEventListener('message', function(event)
{ 
    var item = event.data;
    switch(item.action) {
        case 'show':
            appendAllSlots(item.items, item.slots, 47);
            $(".bg-rgb").show();
            $("#weapon-selection").hide()
            state = 'inventory'
            equipped = item.equipped
            setupClothing()
            return;
        case 'refreshInventory': 
            appendAllSlots(item.items, item.slots, 47);
            return;
        case 'weapon_selection':
            if (state == '') $("#weapon-selection").fadeIn()
            return;
        case 'weapon_selection_close':
            if (state == '') $("#weapon-selection").fadeOut()
            return;
        case 'slotAnimation':
            slotAnimation(item.id, item.name)
            return;
        case 'refreshClothing':
            equipped = item.equipped
            setupClothing()
            return;
        default:
            return;
    }
});

//clothing-setup

function setupClothing(){
    $.each(equipped, function(k,v){
        if (v) {
            changeClasses('#clothing-' + k, 'button-small', 'button-small-disabled')
        } else changeClasses("#clothing-" + k, 'button-small-disabled', 'button-small')
    })
}

//inventory-setup//

function appendAllSlots(items, slots, limit) {
    $("#player-inventory").html('');
    for (let i=0; i <= limit; i++) {
        $("#player-inventory").append(`
            <div class="item-slot" id="item-slot-`+ i +`"></div>
        `);
    };
    inventorySetup(items, slots)
};

//global click events//
for (let i = 0; i <=3; i++) {
    $("#slot-managment-" + i).click(function(){
        $.post('http://' + resourceName + '/setSlot', JSON.stringify({
            item : itemData, slot : i 
        }));
        slotsSetup(i, itemData.name)
        removeSlotManager()
    })
}

function slotsSetup(id, name) {
    $("#slot-" + id).html('')
    $("#slot-out-" + id).html('')
    $("#slot-managment-" + id).html('')
    if (name == 'none') img = svgData['empty-slot']
    else img = '<img class="slot-image" src="img/' + name + '.png"/>'
    $("#slot-" + id).append(` 
        <div class="slot-label">Slot `+ id +`</div>
        `+ img +`
    `)

    $("#slot-out-" + id).append(` 
        <div class="slot-label">Slot `+ id +`</div>
        `+ img +`
    `)
    $("#slot-managment-" + id).append(` 
        <div class="slot-label">Slot `+ id +`</div>
        `+ img +`
    `)
}

function inventorySetup(items, slots) {
    for (let i=0; i <=3; i++) {
        slotsSetup(i, slots[i][0])
    }
    let counter = 0
    let itemsFoundInSlot = []
    $.each(items, function(k,v) {
        state = 'inventory'
        for (let i=0; i<=3; i++) {
            if (slots[i][0] == v.name) itemsFoundInSlot[i] = v.name
        }
        $("#item-slot-" + k).append(`
            <img class="item-img" src="img/`+ v.name +`.png"/>
            `+(v.type == 'item_money' ? '<div class="disabled-item-counter" id="item-count-' + k + '">' + kFormatter(v.count) + '</div>' : '<div class="disabled-item-counter" id="item-count-' + k + '">' + v.count + '/' + v.limit + '</div>')+`
        `)
        if (k == selected) {
            changeClasses("#item-count-" + k, 'disabled-item-counter', 'item-counter')
            itemDescription(v.label, v.usable, v.desc)
        }
        $("#item-slot-" + k).click(function(event) {
            if (k != selected) {
                changeClasses('#item-count-' + k, 'disabled-item-counter', 'item-counter')
                changeClasses('#item-count-' + selected, 'item-counter', 'disabled-item-counter')
            }
            selected = k
            itemData = v
            itemDescription(v.label, v.usable, v.desc)
            if (event.shiftKey) useItem(v.name, v.usable)
            else if (event.altKey) slotManagment(slots)
        })
        draggableSlot("#item-slot-" + k, v)
        counter ++
    });
    for (let i=0; i<=3; i++) {
        if (typeof itemsFoundInSlot[i] === 'undefined') {
            $.post('http://' + resourceName + '/setSlot', JSON.stringify({
                item : {name : 'none', type : ''}, slot : i 
            }));
            slotsSetup(i, 'none')
        }
    }
    $("#item-count").html(counter + '/' + '47')
};


function draggableSlot(id, item) {
    $(id).draggable({
        helper: 'clone',
        appendTo: 'body',
        zIndex: 99999,
        revert: 'invalid',
        start: function (event, ui) {
            itemData = item
            $(id).css('border', 'none')
            $(id + " div").hide()
            $(id + " img").hide()
        },
        stop: function () {
            $(id).css('border', '0.5px solid rgba(128, 128, 128, 0.555)');
            $(id + " div").show()
            $(id + " img").show()
        }
    });
}

function itemDescription(label, usable, desc) {
    $("#item-name").html(label)
    if (usable) $("#item-use").html('Upotrebljivo')
    else $("#item-use").html('Neupotrebljivo')
    if (typeof desc === 'undefined') $("#item-desc").html('Nema opisa')
    else $('#item-desc').html(desc)
}

//droppable-events//
$('#drop').droppable({
    hoverClass: 'hoverControl',
    drop: function (event, ui) {
        if (state == 'inventory') createDialogActions('Bacanje itema', dropItem)
    }
});

$('#give').droppable({
    hoverClass: 'hoverControl',
    drop: function (event, ui) {
        if (state == 'inventory') createDialogActions('Prebacivanje itema', giveItem)
    }
});

//item-interactions//
function useItem(name, usable) {
    if (usable) {
        $.post("https://" + resourceName + "/useItem", JSON.stringify({
            item: name
        }));
        closeInventory()
    }
}

function dropItem(number, length) {
    if (length <= 0) {$("#action-error").html('Morate uneti pozitivan broj'); return false;} 
    if (itemData.count < number) {$("#action-error").html('Nemate tu kolicinu'); return false;}
    if (itemData.canRemove == 0) {$("#action-error").html('Ovaj item ne moze da se baci'); return false;}
    $.post('http://' + resourceName + '/dropItem', JSON.stringify({
        item : itemData, number : number
    }));
    removeActions()
}

function giveItem(number, length) {
    if (length <= 0) {$("#action-error").html('Morate uneti pozitivan broj'); return false;} 
    if (itemData.count < number) {$("#action-error").html('Nemate tu kolicinu'); return false;}
    if (itemData.canRemove == 0) {$("#action-error").html('Ovaj item ne moze da se prebaci'); return false;}
    $.post('http://' + resourceName + '/giveItem', JSON.stringify({
        item : itemData, number : number
    }));
    removeActions()
}

function createDialogActions(label, fn) {
    if (state == 'inventory') {
        state = 'dialog'
        $(".bg-rgb").append(`
            <div class="actions" id="actions"> 
                <h1>`+label+`</h1>
                <form><input type="number" class="action-input my-2" placeholder="Unesite kolicinu" id="count-value"></input></form>
                <button class="action-btn-shape action-btn my-2" id="dialog-confirm">Potvrdi</button>
                <button class="action-btn-shape action-cancel-btn my-2" id="dialog-cancel">Otkazi</button>
                <p id="action-error"></p>
            </div>
        `)
        $("#dialog-confirm").click(function() {
            fn(parseInt(document.getElementById('count-value').value), document.getElementById('count-value').value.length);
        })
        $("#dialog-cancel").click(function() {
            removeActions()
        })
    }
}

function removeActions() {
    $("#actions").remove()
    state = 'inventory'
}

function slotManagment() {
    if (state == 'inventory') {
        state = 'slot-manager'
        $("#slot-managment").show()
    }
}

function removeSlotManager() {
    $("#slot-managment").hide()
    state = 'inventory'
}

//body-key-interactions//
$("body").on("keyup", function (key) {
    if (key.which == 27) {
        if (state == 'inventory') {
            closeInventory()
        } else if (state == 'dialog') {
            removeActions();
        } else if (state == 'slot-manager') {
            removeSlotManager()
        }
    }
});

function closeInventory() {
    selected = 0;
    $.post('http://' + resourceName + '/close', JSON.stringify({}));
    $(".bg-rgb").hide()
    state = ''
}
//utilis//
function kFormatter(num) {
    return Math.abs(num) > 999 ? Math.sign(num)*((Math.abs(num)/1000).toFixed(1)) + 'k' : Math.sign(num)*Math.abs(num)
}

function changeClasses(id, remove, add) {
    $(id).removeClass(remove)
    $(id).addClass(add)
}

function slotAnimation(id, name) {
    if (isSlotAnimation == false) {
        isSlotAnimation = true
        if (name == 'none') img = svgData['empty-slot']
        else img = '<img class="slot-image" src="img/' + name + '.png"/>'
        $("#slot-animation").append(`
            <div class="slot-label">Slot `+ id +`</div>
            `+ img +`
        `)
        $("#slot-animation").animate({bottom:'10%'}, 400)
        setTimeout(function(){ 
            $("#slot-animation").animate({bottom:'-100%'}, 800)
        }, 2000)
        setTimeout(function() {
            $("#slot-animation").html('')
            isSlotAnimation = false
        }, 3000)
    }
}

$("#clothing-helmet_1").click(function() {
    if (canChange)
    $.post('http://' + resourceName + '/toggleClothing', JSON.stringify({
        type : 'helmet_1', type2: 'helmet_2',status: equipped['helmet_1']
    }))
})

$("#clothing-glasses_1").click(function(){
    if (canChange)
    $.post('http://' + resourceName + '/toggleClothing', JSON.stringify({
        type : 'glasses_1', type2: 'glasses_2',status: equipped['glasses_1']
    }))
})

$("#clothing-chain_1").click(function(){
    if (canChange)
    $.post('http://' + resourceName + '/toggleClothing', JSON.stringify({
        type : 'chain_1', type2: 'chain_2', status: equipped['chain_1']
    }))
})

$("#clothing-watches_1").click(function(){
    if (canChange)
    $.post('http://' + resourceName + '/toggleClothing', JSON.stringify({
        type : 'watches_1', type2: 'watches_2', status: equipped['watches_1']
    }))
})

$("#clothing-reset").click(function(){
    if (canChange)
    $.post('http://' + resourceName + '/resetClothing', JSON.stringify({}))
})

//desno

$("#clothing-torso_1").click(function(){
    $.post('http://' + resourceName + '/toggleClothing', JSON.stringify({
        type : 'torso_1', type2: 'torso_2', status: equipped['torso_1']
    }))
})

$("#clothing-tshirt_1").click(function(){
    $.post('http://' + resourceName + '/toggleClothing', JSON.stringify({
        type : 'tshirt_1', type2: 'tshirt_2', status: equipped['tshirt_1']
    }))
})

$("#clothing-bproof_1").click(function(){
    $.post('http://' + resourceName + '/toggleClothing', JSON.stringify({
        type : 'bproof_1', type2: 'bproof_2', status: equipped['bproof_1']
    }))
})

$("#clothing-pants_1").click(function(){
    $.post('http://' + resourceName + '/toggleClothing', JSON.stringify({
        type : 'pants_1', type2: 'pants_2', status: equipped['pants_1']
    }))
})

//gore dole

$("#clothing-mask_1").click(function(){
    $.post('http://' + resourceName + '/toggleClothing', JSON.stringify({
        type : 'mask_1', type2: 'mask_2', status: equipped['mask_1']
    }))
})

$("#clothing-shoes_1").click(function(){
    $.post('http://' + resourceName + '/toggleClothing', JSON.stringify({
        type : 'shoes_1', type2: 'shoes_2', status: equipped['shoes_1']
    }))
})

$("input").keydown(function(event) {
    if (event.keyCode == 13) {
        return false;
    }
});

$("button").keydown(function(event) {
    if (event.keyCode == 13) {
        return false;
    }
})