(() => {
  var __defProp = Object.defineProperty;
  var __defNormalProp = (obj, key, value) => key in obj ? __defProp(obj, key, { enumerable: true, configurable: true, writable: true, value }) : obj[key] = value;
  var __publicField = (obj, key, value) => {
    __defNormalProp(obj, typeof key !== "symbol" ? key + "" : key, value);
    return value;
  };

  // node_modules/alpinejs/dist/module.esm.js
  var flushPending = false;
  var flushing = false;
  var queue = [];
  var lastFlushedIndex = -1;
  var transactionActive = false;
  function scheduler(callback) {
    queueJob(callback);
  }
  function startTransaction() {
    transactionActive = true;
  }
  function commitTransaction() {
    transactionActive = false;
    queueFlush();
  }
  function queueJob(job) {
    if (!queue.includes(job))
      queue.push(job);
    queueFlush();
  }
  function dequeueJob(job) {
    let index = queue.indexOf(job);
    if (index !== -1 && index > lastFlushedIndex)
      queue.splice(index, 1);
  }
  function queueFlush() {
    if (!flushing && !flushPending) {
      if (transactionActive)
        return;
      flushPending = true;
      queueMicrotask(flushJobs);
    }
  }
  function flushJobs() {
    flushPending = false;
    flushing = true;
    for (let i = 0; i < queue.length; i++) {
      queue[i]();
      lastFlushedIndex = i;
    }
    queue.length = 0;
    lastFlushedIndex = -1;
    flushing = false;
  }
  var reactive;
  var effect;
  var release;
  var raw;
  var shouldSchedule = true;
  function disableEffectScheduling(callback) {
    shouldSchedule = false;
    callback();
    shouldSchedule = true;
  }
  function setReactivityEngine(engine) {
    reactive = engine.reactive;
    release = engine.release;
    effect = (callback) => engine.effect(callback, { scheduler: (task) => {
      if (shouldSchedule) {
        scheduler(task);
      } else {
        task();
      }
    } });
    raw = engine.raw;
  }
  function overrideEffect(override) {
    effect = override;
  }
  function elementBoundEffect(el) {
    let cleanup2 = () => {
    };
    let wrappedEffect = (callback) => {
      let effectReference = effect(callback);
      if (!el._x_effects) {
        el._x_effects = /* @__PURE__ */ new Set();
        el._x_runEffects = () => {
          el._x_effects.forEach((i) => i());
        };
      }
      el._x_effects.add(effectReference);
      cleanup2 = () => {
        if (effectReference === void 0)
          return;
        el._x_effects.delete(effectReference);
        release(effectReference);
      };
      return effectReference;
    };
    return [wrappedEffect, () => {
      cleanup2();
    }];
  }
  function watch(getter, callback) {
    let firstTime = true;
    let oldValue;
    let oldValueJSON;
    let effectReference = effect(() => {
      let value = getter();
      let newJSON = JSON.stringify(value);
      if (!firstTime) {
        if (typeof value === "object" || value !== oldValue) {
          let previousValue = typeof oldValue === "object" ? JSON.parse(oldValueJSON) : oldValue;
          queueMicrotask(() => {
            callback(value, previousValue);
          });
        }
      }
      oldValue = value;
      oldValueJSON = newJSON;
      firstTime = false;
    });
    return () => release(effectReference);
  }
  async function transaction(callback) {
    startTransaction();
    try {
      await callback();
      await Promise.resolve();
    } finally {
      commitTransaction();
    }
  }
  var onAttributeAddeds = [];
  var onElRemoveds = [];
  var onElAddeds = [];
  function onElAdded(callback) {
    onElAddeds.push(callback);
  }
  function onElRemoved(el, callback) {
    if (typeof callback === "function") {
      if (!el._x_cleanups)
        el._x_cleanups = [];
      el._x_cleanups.push(callback);
    } else {
      callback = el;
      onElRemoveds.push(callback);
    }
  }
  function onAttributesAdded(callback) {
    onAttributeAddeds.push(callback);
  }
  function onAttributeRemoved(el, name, callback) {
    if (!el._x_attributeCleanups)
      el._x_attributeCleanups = {};
    if (!el._x_attributeCleanups[name])
      el._x_attributeCleanups[name] = [];
    el._x_attributeCleanups[name].push(callback);
  }
  function cleanupAttributes(el, names) {
    if (!el._x_attributeCleanups)
      return;
    Object.entries(el._x_attributeCleanups).forEach(([name, value]) => {
      if (names === void 0 || names.includes(name)) {
        value.forEach((i) => i());
        delete el._x_attributeCleanups[name];
      }
    });
  }
  function cleanupElement(el) {
    el._x_effects?.forEach(dequeueJob);
    while (el._x_cleanups?.length)
      el._x_cleanups.pop()();
  }
  var observer = new MutationObserver(onMutate);
  var currentlyObserving = false;
  function startObservingMutations() {
    observer.observe(document, { subtree: true, childList: true, attributes: true, attributeOldValue: true });
    currentlyObserving = true;
  }
  function stopObservingMutations() {
    flushObserver();
    observer.disconnect();
    currentlyObserving = false;
  }
  var queuedMutations = [];
  function flushObserver() {
    let records = observer.takeRecords();
    queuedMutations.push(() => records.length > 0 && onMutate(records));
    let queueLengthWhenTriggered = queuedMutations.length;
    queueMicrotask(() => {
      if (queuedMutations.length === queueLengthWhenTriggered) {
        while (queuedMutations.length > 0)
          queuedMutations.shift()();
      }
    });
  }
  function mutateDom(callback) {
    if (!currentlyObserving)
      return callback();
    stopObservingMutations();
    let result = callback();
    startObservingMutations();
    return result;
  }
  var isCollecting = false;
  var deferredMutations = [];
  function deferMutations() {
    isCollecting = true;
  }
  function flushAndStopDeferringMutations() {
    isCollecting = false;
    onMutate(deferredMutations);
    deferredMutations = [];
  }
  function onMutate(mutations) {
    if (isCollecting) {
      deferredMutations = deferredMutations.concat(mutations);
      return;
    }
    let addedNodes = [];
    let removedNodes = /* @__PURE__ */ new Set();
    let addedAttributes = /* @__PURE__ */ new Map();
    let removedAttributes = /* @__PURE__ */ new Map();
    for (let i = 0; i < mutations.length; i++) {
      if (mutations[i].target._x_ignoreMutationObserver)
        continue;
      if (mutations[i].type === "childList") {
        mutations[i].removedNodes.forEach((node) => {
          if (node.nodeType !== 1)
            return;
          if (!node._x_marker)
            return;
          removedNodes.add(node);
        });
        mutations[i].addedNodes.forEach((node) => {
          if (node.nodeType !== 1)
            return;
          if (removedNodes.has(node)) {
            removedNodes.delete(node);
            return;
          }
          if (node._x_marker)
            return;
          addedNodes.push(node);
        });
      }
      if (mutations[i].type === "attributes") {
        let el = mutations[i].target;
        let name = mutations[i].attributeName;
        let oldValue = mutations[i].oldValue;
        let add2 = () => {
          if (!addedAttributes.has(el))
            addedAttributes.set(el, []);
          addedAttributes.get(el).push({ name, value: el.getAttribute(name) });
        };
        let remove = () => {
          if (!removedAttributes.has(el))
            removedAttributes.set(el, []);
          removedAttributes.get(el).push(name);
        };
        if (el.hasAttribute(name) && oldValue === null) {
          add2();
        } else if (el.hasAttribute(name)) {
          remove();
          add2();
        } else {
          remove();
        }
      }
    }
    removedAttributes.forEach((attrs, el) => {
      cleanupAttributes(el, attrs);
    });
    addedAttributes.forEach((attrs, el) => {
      onAttributeAddeds.forEach((i) => i(el, attrs));
    });
    for (let node of removedNodes) {
      if (addedNodes.some((i) => i.contains(node)))
        continue;
      onElRemoveds.forEach((i) => i(node));
    }
    for (let node of addedNodes) {
      if (!node.isConnected)
        continue;
      onElAddeds.forEach((i) => i(node));
    }
    addedNodes = null;
    removedNodes = null;
    addedAttributes = null;
    removedAttributes = null;
  }
  function scope(node) {
    return mergeProxies(closestDataStack(node));
  }
  function addScopeToNode(node, data2, referenceNode) {
    node._x_dataStack = [data2, ...closestDataStack(referenceNode || node)];
    return () => {
      node._x_dataStack = node._x_dataStack.filter((i) => i !== data2);
    };
  }
  function closestDataStack(node) {
    if (node._x_dataStack)
      return node._x_dataStack;
    if (typeof ShadowRoot === "function" && node instanceof ShadowRoot) {
      return closestDataStack(node.host);
    }
    if (!node.parentNode) {
      return [];
    }
    return closestDataStack(node.parentNode);
  }
  function mergeProxies(objects) {
    return new Proxy({ objects }, mergeProxyTrap);
  }
  function keyInPrototypeChain(obj, key) {
    if (obj === null || obj === Object.prototype)
      return null;
    if (Object.prototype.hasOwnProperty.call(obj, key))
      return obj;
    return keyInPrototypeChain(Object.getPrototypeOf(obj), key);
  }
  var mergeProxyTrap = {
    ownKeys({ objects }) {
      return Array.from(new Set(objects.flatMap((i) => Object.keys(i))));
    },
    has({ objects }, name) {
      if (name == Symbol.unscopables)
        return false;
      return objects.some((obj) => Object.prototype.hasOwnProperty.call(obj, name) || Reflect.has(obj, name));
    },
    get({ objects }, name, thisProxy) {
      if (name == "toJSON")
        return collapseProxies;
      return Reflect.get(objects.find((obj) => Reflect.has(obj, name)) || {}, name, thisProxy);
    },
    set({ objects }, name, value, thisProxy) {
      let target;
      for (const obj of objects) {
        target = keyInPrototypeChain(obj, name);
        if (target)
          break;
      }
      if (!target)
        target = objects[objects.length - 1];
      const descriptor = Object.getOwnPropertyDescriptor(target, name);
      if (descriptor?.set && descriptor?.get)
        return descriptor.set.call(thisProxy, value) || true;
      return Reflect.set(target, name, value);
    }
  };
  function collapseProxies() {
    let keys = Reflect.ownKeys(this);
    return keys.reduce((acc, key) => {
      acc[key] = Reflect.get(this, key);
      return acc;
    }, {});
  }
  function initInterceptors(data2) {
    let isObject3 = (val) => typeof val === "object" && !Array.isArray(val) && val !== null;
    let recurse = (obj, basePath = "") => {
      Object.entries(Object.getOwnPropertyDescriptors(obj)).forEach(([key, { value, enumerable }]) => {
        if (enumerable === false || value === void 0)
          return;
        if (typeof value === "object" && value !== null && value.__v_skip)
          return;
        let path = basePath === "" ? key : `${basePath}.${key}`;
        if (typeof value === "object" && value !== null && value._x_interceptor) {
          obj[key] = value.initialize(data2, path, key);
        } else {
          if (isObject3(value) && value !== obj && !(value instanceof Element)) {
            recurse(value, path);
          }
        }
      });
    };
    return recurse(data2);
  }
  function interceptor(callback, mutateObj = () => {
  }) {
    let obj = {
      initialValue: void 0,
      _x_interceptor: true,
      initialize(data2, path, key) {
        return callback(this.initialValue, () => get(data2, path), (value) => set(data2, path, value), path, key);
      }
    };
    mutateObj(obj);
    return (initialValue) => {
      if (typeof initialValue === "object" && initialValue !== null && initialValue._x_interceptor) {
        let initialize = obj.initialize.bind(obj);
        obj.initialize = (data2, path, key) => {
          let innerValue = initialValue.initialize(data2, path, key);
          obj.initialValue = innerValue;
          return initialize(data2, path, key);
        };
      } else {
        obj.initialValue = initialValue;
      }
      return obj;
    };
  }
  function get(obj, path) {
    return path.split(".").reduce((carry, segment) => carry[segment], obj);
  }
  function set(obj, path, value) {
    if (typeof path === "string")
      path = path.split(".");
    if (path.length === 1)
      obj[path[0]] = value;
    else if (path.length === 0)
      throw error;
    else {
      if (obj[path[0]])
        return set(obj[path[0]], path.slice(1), value);
      else {
        obj[path[0]] = {};
        return set(obj[path[0]], path.slice(1), value);
      }
    }
  }
  var magics = {};
  function magic(name, callback) {
    magics[name] = callback;
  }
  function injectMagics(obj, el) {
    let memoizedUtilities = getUtilities(el);
    Object.entries(magics).forEach(([name, callback]) => {
      Object.defineProperty(obj, `$${name}`, {
        get() {
          return callback(el, memoizedUtilities);
        },
        enumerable: false
      });
    });
    return obj;
  }
  function getUtilities(el) {
    let [utilities, cleanup2] = getElementBoundUtilities(el);
    let utils = { interceptor, ...utilities };
    onElRemoved(el, cleanup2);
    return utils;
  }
  function tryCatch(el, expression, callback, ...args) {
    try {
      return callback(...args);
    } catch (e) {
      handleError(e, el, expression);
    }
  }
  function handleError(...args) {
    return errorHandler(...args);
  }
  var errorHandler = normalErrorHandler;
  function setErrorHandler(handler4) {
    errorHandler = handler4;
  }
  function normalErrorHandler(error2, el, expression = void 0) {
    error2 = Object.assign(error2 ?? { message: "No error message given." }, { el, expression });
    console.warn(`Alpine Expression Error: ${error2.message}

${expression ? 'Expression: "' + expression + '"\n\n' : ""}`, el);
    setTimeout(() => {
      throw error2;
    }, 0);
  }
  var shouldAutoEvaluateFunctions = true;
  function dontAutoEvaluateFunctions(callback) {
    let cache = shouldAutoEvaluateFunctions;
    shouldAutoEvaluateFunctions = false;
    let result = callback();
    shouldAutoEvaluateFunctions = cache;
    return result;
  }
  function evaluate(el, expression, extras = {}) {
    let result;
    evaluateLater(el, expression)((value) => result = value, extras);
    return result;
  }
  function evaluateLater(...args) {
    return theEvaluatorFunction(...args);
  }
  var theEvaluatorFunction = () => {
  };
  function setEvaluator(newEvaluator) {
    theEvaluatorFunction = newEvaluator;
  }
  var theRawEvaluatorFunction;
  function setRawEvaluator(newEvaluator) {
    theRawEvaluatorFunction = newEvaluator;
  }
  function normalEvaluator(el, expression) {
    let overriddenMagics = {};
    injectMagics(overriddenMagics, el);
    let dataStack = [overriddenMagics, ...closestDataStack(el)];
    let evaluator = typeof expression === "function" ? generateEvaluatorFromFunction(dataStack, expression) : generateEvaluatorFromString(dataStack, expression, el);
    return tryCatch.bind(null, el, expression, evaluator);
  }
  function generateEvaluatorFromFunction(dataStack, func) {
    return (receiver = () => {
    }, { scope: scope2 = {}, params = [], context } = {}) => {
      if (!shouldAutoEvaluateFunctions) {
        runIfTypeOfFunction(receiver, func, mergeProxies([scope2, ...dataStack]), params);
        return;
      }
      let result = func.apply(mergeProxies([scope2, ...dataStack]), params);
      runIfTypeOfFunction(receiver, result);
    };
  }
  var evaluatorMemo = {};
  function generateFunctionFromString(expression, el) {
    if (evaluatorMemo[expression]) {
      return evaluatorMemo[expression];
    }
    let AsyncFunction = Object.getPrototypeOf(async function() {
    }).constructor;
    let rightSideSafeExpression = /^[\n\s]*if.*\(.*\)/.test(expression.trim()) || /^(let|const)\s/.test(expression.trim()) ? `(async()=>{ ${expression} })()` : expression;
    const safeAsyncFunction = () => {
      try {
        let func2 = new AsyncFunction(["__self", "scope"], `with (scope) { __self.result = ${rightSideSafeExpression} }; __self.finished = true; return __self.result;`);
        Object.defineProperty(func2, "name", {
          value: `[Alpine] ${expression}`
        });
        return func2;
      } catch (error2) {
        handleError(error2, el, expression);
        return Promise.resolve();
      }
    };
    let func = safeAsyncFunction();
    evaluatorMemo[expression] = func;
    return func;
  }
  function generateEvaluatorFromString(dataStack, expression, el) {
    let func = generateFunctionFromString(expression, el);
    return (receiver = () => {
    }, { scope: scope2 = {}, params = [], context } = {}) => {
      func.result = void 0;
      func.finished = false;
      let completeScope = mergeProxies([scope2, ...dataStack]);
      if (typeof func === "function") {
        let promise = func.call(context, func, completeScope).catch((error2) => handleError(error2, el, expression));
        if (func.finished) {
          runIfTypeOfFunction(receiver, func.result, completeScope, params, el);
          func.result = void 0;
        } else {
          promise.then((result) => {
            runIfTypeOfFunction(receiver, result, completeScope, params, el);
          }).catch((error2) => handleError(error2, el, expression)).finally(() => func.result = void 0);
        }
      }
    };
  }
  function runIfTypeOfFunction(receiver, value, scope2, params, el) {
    if (shouldAutoEvaluateFunctions && typeof value === "function") {
      let result = value.apply(scope2, params);
      if (result instanceof Promise) {
        result.then((i) => runIfTypeOfFunction(receiver, i, scope2, params)).catch((error2) => handleError(error2, el, value));
      } else {
        receiver(result);
      }
    } else if (typeof value === "object" && value instanceof Promise) {
      value.then((i) => receiver(i));
    } else {
      receiver(value);
    }
  }
  function evaluateRaw(...args) {
    return theRawEvaluatorFunction(...args);
  }
  function normalRawEvaluator(el, expression, extras = {}) {
    let overriddenMagics = {};
    injectMagics(overriddenMagics, el);
    let dataStack = [overriddenMagics, ...closestDataStack(el)];
    let scope2 = mergeProxies([extras.scope ?? {}, ...dataStack]);
    let params = extras.params ?? [];
    if (expression.includes("await")) {
      let AsyncFunction = Object.getPrototypeOf(async function() {
      }).constructor;
      let rightSideSafeExpression = /^[\n\s]*if.*\(.*\)/.test(expression.trim()) || /^(let|const)\s/.test(expression.trim()) ? `(async()=>{ ${expression} })()` : expression;
      let func = new AsyncFunction(["scope"], `with (scope) { let __result = ${rightSideSafeExpression}; return __result }`);
      let result = func.call(extras.context, scope2);
      return result;
    } else {
      let rightSideSafeExpression = /^[\n\s]*if.*\(.*\)/.test(expression.trim()) || /^(let|const)\s/.test(expression.trim()) ? `(()=>{ ${expression} })()` : expression;
      let func = new Function(["scope"], `with (scope) { let __result = ${rightSideSafeExpression}; return __result }`);
      let result = func.call(extras.context, scope2);
      if (typeof result === "function" && shouldAutoEvaluateFunctions) {
        return result.apply(scope2, params);
      }
      return result;
    }
  }
  var prefixAsString = "x-";
  function prefix(subject = "") {
    return prefixAsString + subject;
  }
  function setPrefix(newPrefix) {
    prefixAsString = newPrefix;
  }
  var directiveHandlers = {};
  function directive(name, callback) {
    directiveHandlers[name] = callback;
    return {
      before(directive2) {
        if (!directiveHandlers[directive2]) {
          console.warn(String.raw`Cannot find directive \`${directive2}\`. \`${name}\` will use the default order of execution`);
          return;
        }
        const pos = directiveOrder.indexOf(directive2);
        directiveOrder.splice(pos >= 0 ? pos : directiveOrder.indexOf("DEFAULT"), 0, name);
      }
    };
  }
  function directiveExists(name) {
    return Object.keys(directiveHandlers).includes(name);
  }
  function directives(el, attributes, originalAttributeOverride) {
    attributes = Array.from(attributes);
    if (el._x_virtualDirectives) {
      let vAttributes = Object.entries(el._x_virtualDirectives).map(([name, value]) => ({ name, value }));
      let staticAttributes = attributesOnly(vAttributes);
      vAttributes = vAttributes.map((attribute) => {
        if (staticAttributes.find((attr) => attr.name === attribute.name)) {
          return {
            name: `x-bind:${attribute.name}`,
            value: `"${attribute.value}"`
          };
        }
        return attribute;
      });
      attributes = attributes.concat(vAttributes);
    }
    let transformedAttributeMap = {};
    let directives2 = attributes.map(toTransformedAttributes((newName, oldName) => transformedAttributeMap[newName] = oldName)).filter(outNonAlpineAttributes).map(toParsedDirectives(transformedAttributeMap, originalAttributeOverride)).sort(byPriority);
    return directives2.map((directive2) => {
      return getDirectiveHandler(el, directive2);
    });
  }
  function attributesOnly(attributes) {
    return Array.from(attributes).map(toTransformedAttributes()).filter((attr) => !outNonAlpineAttributes(attr));
  }
  var isDeferringHandlers = false;
  var directiveHandlerStacks = /* @__PURE__ */ new Map();
  var currentHandlerStackKey = Symbol();
  function deferHandlingDirectives(callback) {
    isDeferringHandlers = true;
    let key = Symbol();
    currentHandlerStackKey = key;
    directiveHandlerStacks.set(key, []);
    let flushHandlers = () => {
      while (directiveHandlerStacks.get(key).length)
        directiveHandlerStacks.get(key).shift()();
      directiveHandlerStacks.delete(key);
    };
    let stopDeferring = () => {
      isDeferringHandlers = false;
      flushHandlers();
    };
    callback(flushHandlers);
    stopDeferring();
  }
  function getElementBoundUtilities(el) {
    let cleanups = [];
    let cleanup2 = (callback) => cleanups.push(callback);
    let [effect3, cleanupEffect] = elementBoundEffect(el);
    cleanups.push(cleanupEffect);
    let utilities = {
      Alpine: alpine_default,
      effect: effect3,
      cleanup: cleanup2,
      evaluateLater: evaluateLater.bind(evaluateLater, el),
      evaluate: evaluate.bind(evaluate, el)
    };
    let doCleanup = () => cleanups.forEach((i) => i());
    return [utilities, doCleanup];
  }
  function getDirectiveHandler(el, directive2) {
    let noop = () => {
    };
    let handler4 = directiveHandlers[directive2.type] || noop;
    let [utilities, cleanup2] = getElementBoundUtilities(el);
    onAttributeRemoved(el, directive2.original, cleanup2);
    let fullHandler = () => {
      if (el._x_ignore || el._x_ignoreSelf)
        return;
      handler4.inline && handler4.inline(el, directive2, utilities);
      handler4 = handler4.bind(handler4, el, directive2, utilities);
      isDeferringHandlers ? directiveHandlerStacks.get(currentHandlerStackKey).push(handler4) : handler4();
    };
    fullHandler.runCleanups = cleanup2;
    return fullHandler;
  }
  var startingWith = (subject, replacement) => ({ name, value }) => {
    if (name.startsWith(subject))
      name = name.replace(subject, replacement);
    return { name, value };
  };
  var into = (i) => i;
  function toTransformedAttributes(callback = () => {
  }) {
    return ({ name, value }) => {
      let { name: newName, value: newValue } = attributeTransformers.reduce((carry, transform) => {
        return transform(carry);
      }, { name, value });
      if (newName !== name)
        callback(newName, name);
      return { name: newName, value: newValue };
    };
  }
  var attributeTransformers = [];
  function mapAttributes(callback) {
    attributeTransformers.push(callback);
  }
  function outNonAlpineAttributes({ name }) {
    return alpineAttributeRegex().test(name);
  }
  var alpineAttributeRegex = () => new RegExp(`^${prefixAsString}([^:^.]+)\\b`);
  function toParsedDirectives(transformedAttributeMap, originalAttributeOverride) {
    return ({ name, value }) => {
      if (name === value)
        value = "";
      let typeMatch = name.match(alpineAttributeRegex());
      let valueMatch = name.match(/:([a-zA-Z0-9\-_:]+)/);
      let modifiers = name.match(/\.[^.\]]+(?=[^\]]*$)/g) || [];
      let original = originalAttributeOverride || transformedAttributeMap[name] || name;
      return {
        type: typeMatch ? typeMatch[1] : null,
        value: valueMatch ? valueMatch[1] : null,
        modifiers: modifiers.map((i) => i.replace(".", "")),
        expression: value,
        original
      };
    };
  }
  var DEFAULT = "DEFAULT";
  var directiveOrder = [
    "ignore",
    "ref",
    "id",
    "data",
    "anchor",
    "bind",
    "init",
    "for",
    "model",
    "modelable",
    "transition",
    "show",
    "if",
    DEFAULT,
    "teleport"
  ];
  function byPriority(a, b) {
    let typeA = directiveOrder.indexOf(a.type) === -1 ? DEFAULT : a.type;
    let typeB = directiveOrder.indexOf(b.type) === -1 ? DEFAULT : b.type;
    return directiveOrder.indexOf(typeA) - directiveOrder.indexOf(typeB);
  }
  function dispatch(el, name, detail = {}, options = {}) {
    return el.dispatchEvent(new CustomEvent(name, {
      detail,
      bubbles: true,
      composed: true,
      cancelable: true,
      ...options
    }));
  }
  function walk(el, callback) {
    if (typeof ShadowRoot === "function" && el instanceof ShadowRoot) {
      Array.from(el.children).forEach((el2) => walk(el2, callback));
      return;
    }
    let skip = false;
    callback(el, () => skip = true);
    if (skip)
      return;
    let node = el.firstElementChild;
    while (node) {
      walk(node, callback, false);
      node = node.nextElementSibling;
    }
  }
  function warn(message, ...args) {
    console.warn(`Alpine Warning: ${message}`, ...args);
  }
  var started = false;
  function start() {
    if (started)
      warn("Alpine has already been initialized on this page. Calling Alpine.start() more than once can cause problems.");
    started = true;
    if (!document.body)
      warn("Unable to initialize. Trying to load Alpine before `<body>` is available. Did you forget to add `defer` in Alpine's `<script>` tag?");
    dispatch(document, "alpine:init");
    dispatch(document, "alpine:initializing");
    startObservingMutations();
    onElAdded((el) => initTree(el, walk));
    onElRemoved((el) => destroyTree(el));
    onAttributesAdded((el, attrs) => {
      directives(el, attrs).forEach((handle) => handle());
    });
    let outNestedComponents = (el) => !closestRoot(el.parentElement, true);
    Array.from(document.querySelectorAll(allSelectors().join(","))).filter(outNestedComponents).forEach((el) => {
      initTree(el);
    });
    dispatch(document, "alpine:initialized");
    setTimeout(() => {
      warnAboutMissingPlugins();
    });
  }
  var rootSelectorCallbacks = [];
  var initSelectorCallbacks = [];
  function rootSelectors() {
    return rootSelectorCallbacks.map((fn) => fn());
  }
  function allSelectors() {
    return rootSelectorCallbacks.concat(initSelectorCallbacks).map((fn) => fn());
  }
  function addRootSelector(selectorCallback) {
    rootSelectorCallbacks.push(selectorCallback);
  }
  function addInitSelector(selectorCallback) {
    initSelectorCallbacks.push(selectorCallback);
  }
  function closestRoot(el, includeInitSelectors = false) {
    return findClosest(el, (element) => {
      const selectors = includeInitSelectors ? allSelectors() : rootSelectors();
      if (selectors.some((selector) => element.matches(selector)))
        return true;
    });
  }
  function findClosest(el, callback) {
    if (!el)
      return;
    if (callback(el))
      return el;
    if (el._x_teleportBack)
      return findClosest(el._x_teleportBack, callback);
    if (el.parentNode instanceof ShadowRoot) {
      return findClosest(el.parentNode.host, callback);
    }
    if (!el.parentElement)
      return;
    return findClosest(el.parentElement, callback);
  }
  function isRoot(el) {
    return rootSelectors().some((selector) => el.matches(selector));
  }
  var initInterceptors2 = [];
  function interceptInit(callback) {
    initInterceptors2.push(callback);
  }
  var markerDispenser = 1;
  function initTree(el, walker = walk, intercept = () => {
  }) {
    if (findClosest(el, (i) => i._x_ignore))
      return;
    deferHandlingDirectives(() => {
      walker(el, (el2, skip) => {
        if (el2._x_marker)
          return;
        intercept(el2, skip);
        initInterceptors2.forEach((i) => i(el2, skip));
        directives(el2, el2.attributes).forEach((handle) => handle());
        if (!el2._x_ignore)
          el2._x_marker = markerDispenser++;
        el2._x_ignore && skip();
      });
    });
  }
  function destroyTree(root, walker = walk) {
    walker(root, (el) => {
      cleanupElement(el);
      cleanupAttributes(el);
      delete el._x_marker;
    });
  }
  function warnAboutMissingPlugins() {
    let pluginDirectives = [
      ["ui", "dialog", ["[x-dialog], [x-popover]"]],
      ["anchor", "anchor", ["[x-anchor]"]],
      ["sort", "sort", ["[x-sort]"]]
    ];
    pluginDirectives.forEach(([plugin2, directive2, selectors]) => {
      if (directiveExists(directive2))
        return;
      selectors.some((selector) => {
        if (document.querySelector(selector)) {
          warn(`found "${selector}", but missing ${plugin2} plugin`);
          return true;
        }
      });
    });
  }
  var tickStack = [];
  var isHolding = false;
  function nextTick(callback = () => {
  }) {
    queueMicrotask(() => {
      isHolding || setTimeout(() => {
        releaseNextTicks();
      });
    });
    return new Promise((res) => {
      tickStack.push(() => {
        callback();
        res();
      });
    });
  }
  function releaseNextTicks() {
    isHolding = false;
    while (tickStack.length)
      tickStack.shift()();
  }
  function holdNextTicks() {
    isHolding = true;
  }
  function setClasses(el, value) {
    if (Array.isArray(value)) {
      return setClassesFromString(el, value.join(" "));
    } else if (typeof value === "object" && value !== null) {
      return setClassesFromObject(el, value);
    } else if (typeof value === "function") {
      return setClasses(el, value());
    }
    return setClassesFromString(el, value);
  }
  function splitClasses(classString) {
    return classString.split(/\s/).filter(Boolean);
  }
  function setClassesFromString(el, classString) {
    let missingClasses = (classString2) => splitClasses(classString2).filter((i) => !el.classList.contains(i)).filter(Boolean);
    let addClassesAndReturnUndo = (classes) => {
      el.classList.add(...classes);
      return () => {
        el.classList.remove(...classes);
      };
    };
    classString = classString === true ? classString = "" : classString || "";
    return addClassesAndReturnUndo(missingClasses(classString));
  }
  function setClassesFromObject(el, classObject) {
    let forAdd = Object.entries(classObject).flatMap(([classString, bool]) => bool ? splitClasses(classString) : false).filter(Boolean);
    let forRemove = Object.entries(classObject).flatMap(([classString, bool]) => !bool ? splitClasses(classString) : false).filter(Boolean);
    let added = [];
    let removed = [];
    forRemove.forEach((i) => {
      if (el.classList.contains(i)) {
        el.classList.remove(i);
        removed.push(i);
      }
    });
    forAdd.forEach((i) => {
      if (!el.classList.contains(i)) {
        el.classList.add(i);
        added.push(i);
      }
    });
    return () => {
      removed.forEach((i) => el.classList.add(i));
      added.forEach((i) => el.classList.remove(i));
    };
  }
  function setStyles(el, value) {
    if (typeof value === "object" && value !== null) {
      return setStylesFromObject(el, value);
    }
    return setStylesFromString(el, value);
  }
  function setStylesFromObject(el, value) {
    let previousStyles = {};
    Object.entries(value).forEach(([key, value2]) => {
      previousStyles[key] = el.style[key];
      if (!key.startsWith("--")) {
        key = kebabCase(key);
      }
      el.style.setProperty(key, value2);
    });
    setTimeout(() => {
      if (el.style.length === 0) {
        el.removeAttribute("style");
      }
    });
    return () => {
      setStyles(el, previousStyles);
    };
  }
  function setStylesFromString(el, value) {
    let cache = el.getAttribute("style", value);
    el.setAttribute("style", value);
    return () => {
      el.setAttribute("style", cache || "");
    };
  }
  function kebabCase(subject) {
    return subject.replace(/([a-z])([A-Z])/g, "$1-$2").toLowerCase();
  }
  function once(callback, fallback = () => {
  }) {
    let called = false;
    return function() {
      if (!called) {
        called = true;
        callback.apply(this, arguments);
      } else {
        fallback.apply(this, arguments);
      }
    };
  }
  directive("transition", (el, { value, modifiers, expression }, { evaluate: evaluate2 }) => {
    if (typeof expression === "function")
      expression = evaluate2(expression);
    if (expression === false)
      return;
    if (!expression || typeof expression === "boolean") {
      registerTransitionsFromHelper(el, modifiers, value);
    } else {
      registerTransitionsFromClassString(el, expression, value);
    }
  });
  function registerTransitionsFromClassString(el, classString, stage) {
    registerTransitionObject(el, setClasses, "");
    let directiveStorageMap = {
      "enter": (classes) => {
        el._x_transition.enter.during = classes;
      },
      "enter-start": (classes) => {
        el._x_transition.enter.start = classes;
      },
      "enter-end": (classes) => {
        el._x_transition.enter.end = classes;
      },
      "leave": (classes) => {
        el._x_transition.leave.during = classes;
      },
      "leave-start": (classes) => {
        el._x_transition.leave.start = classes;
      },
      "leave-end": (classes) => {
        el._x_transition.leave.end = classes;
      }
    };
    directiveStorageMap[stage](classString);
  }
  function registerTransitionsFromHelper(el, modifiers, stage) {
    registerTransitionObject(el, setStyles);
    let doesntSpecify = !modifiers.includes("in") && !modifiers.includes("out") && !stage;
    let transitioningIn = doesntSpecify || modifiers.includes("in") || ["enter"].includes(stage);
    let transitioningOut = doesntSpecify || modifiers.includes("out") || ["leave"].includes(stage);
    if (modifiers.includes("in") && !doesntSpecify) {
      modifiers = modifiers.filter((i, index) => index < modifiers.indexOf("out"));
    }
    if (modifiers.includes("out") && !doesntSpecify) {
      modifiers = modifiers.filter((i, index) => index > modifiers.indexOf("out"));
    }
    let wantsAll = !modifiers.includes("opacity") && !modifiers.includes("scale");
    let wantsOpacity = wantsAll || modifiers.includes("opacity");
    let wantsScale = wantsAll || modifiers.includes("scale");
    let opacityValue = wantsOpacity ? 0 : 1;
    let scaleValue = wantsScale ? modifierValue(modifiers, "scale", 95) / 100 : 1;
    let delay = modifierValue(modifiers, "delay", 0) / 1e3;
    let origin = modifierValue(modifiers, "origin", "center");
    let property = "opacity, transform";
    let durationIn = modifierValue(modifiers, "duration", 150) / 1e3;
    let durationOut = modifierValue(modifiers, "duration", 75) / 1e3;
    let easing = `cubic-bezier(0.4, 0.0, 0.2, 1)`;
    if (transitioningIn) {
      el._x_transition.enter.during = {
        transformOrigin: origin,
        transitionDelay: `${delay}s`,
        transitionProperty: property,
        transitionDuration: `${durationIn}s`,
        transitionTimingFunction: easing
      };
      el._x_transition.enter.start = {
        opacity: opacityValue,
        transform: `scale(${scaleValue})`
      };
      el._x_transition.enter.end = {
        opacity: 1,
        transform: `scale(1)`
      };
    }
    if (transitioningOut) {
      el._x_transition.leave.during = {
        transformOrigin: origin,
        transitionDelay: `${delay}s`,
        transitionProperty: property,
        transitionDuration: `${durationOut}s`,
        transitionTimingFunction: easing
      };
      el._x_transition.leave.start = {
        opacity: 1,
        transform: `scale(1)`
      };
      el._x_transition.leave.end = {
        opacity: opacityValue,
        transform: `scale(${scaleValue})`
      };
    }
  }
  function registerTransitionObject(el, setFunction, defaultValue = {}) {
    if (!el._x_transition)
      el._x_transition = {
        enter: { during: defaultValue, start: defaultValue, end: defaultValue },
        leave: { during: defaultValue, start: defaultValue, end: defaultValue },
        in(before = () => {
        }, after = () => {
        }) {
          transition(el, setFunction, {
            during: this.enter.during,
            start: this.enter.start,
            end: this.enter.end
          }, before, after);
        },
        out(before = () => {
        }, after = () => {
        }) {
          transition(el, setFunction, {
            during: this.leave.during,
            start: this.leave.start,
            end: this.leave.end
          }, before, after);
        }
      };
  }
  window.Element.prototype._x_toggleAndCascadeWithTransitions = function(el, value, show, hide) {
    const nextTick2 = document.visibilityState === "visible" ? requestAnimationFrame : setTimeout;
    let clickAwayCompatibleShow = () => nextTick2(show);
    if (value) {
      if (el._x_transition && (el._x_transition.enter || el._x_transition.leave)) {
        el._x_transition.enter && (Object.entries(el._x_transition.enter.during).length || Object.entries(el._x_transition.enter.start).length || Object.entries(el._x_transition.enter.end).length) ? el._x_transition.in(show) : clickAwayCompatibleShow();
      } else {
        el._x_transition ? el._x_transition.in(show) : clickAwayCompatibleShow();
      }
      return;
    }
    el._x_hidePromise = el._x_transition ? new Promise((resolve, reject) => {
      el._x_transition.out(() => {
      }, () => resolve(hide));
      el._x_transitioning && el._x_transitioning.beforeCancel(() => reject({ isFromCancelledTransition: true }));
    }) : Promise.resolve(hide);
    queueMicrotask(() => {
      let closest = closestHide(el);
      if (closest) {
        if (!closest._x_hideChildren)
          closest._x_hideChildren = [];
        closest._x_hideChildren.push(el);
      } else {
        nextTick2(() => {
          let hideAfterChildren = (el2) => {
            let carry = Promise.all([
              el2._x_hidePromise,
              ...(el2._x_hideChildren || []).map(hideAfterChildren)
            ]).then(([i]) => i?.());
            delete el2._x_hidePromise;
            delete el2._x_hideChildren;
            return carry;
          };
          hideAfterChildren(el).catch((e) => {
            if (!e.isFromCancelledTransition)
              throw e;
          });
        });
      }
    });
  };
  function closestHide(el) {
    let parent = el.parentNode;
    if (!parent)
      return;
    return parent._x_hidePromise ? parent : closestHide(parent);
  }
  function transition(el, setFunction, { during, start: start2, end } = {}, before = () => {
  }, after = () => {
  }) {
    if (el._x_transitioning)
      el._x_transitioning.cancel();
    if (Object.keys(during).length === 0 && Object.keys(start2).length === 0 && Object.keys(end).length === 0) {
      before();
      after();
      return;
    }
    let undoStart, undoDuring, undoEnd;
    performTransition(el, {
      start() {
        undoStart = setFunction(el, start2);
      },
      during() {
        undoDuring = setFunction(el, during);
      },
      before,
      end() {
        undoStart();
        undoEnd = setFunction(el, end);
      },
      after,
      cleanup() {
        undoDuring();
        undoEnd();
      }
    });
  }
  function performTransition(el, stages) {
    let interrupted, reachedBefore, reachedEnd;
    let finish = once(() => {
      mutateDom(() => {
        interrupted = true;
        if (!reachedBefore)
          stages.before();
        if (!reachedEnd) {
          stages.end();
          releaseNextTicks();
        }
        stages.after();
        if (el.isConnected)
          stages.cleanup();
        delete el._x_transitioning;
      });
    });
    el._x_transitioning = {
      beforeCancels: [],
      beforeCancel(callback) {
        this.beforeCancels.push(callback);
      },
      cancel: once(function() {
        while (this.beforeCancels.length) {
          this.beforeCancels.shift()();
        }
        ;
        finish();
      }),
      finish
    };
    mutateDom(() => {
      stages.start();
      stages.during();
    });
    holdNextTicks();
    requestAnimationFrame(() => {
      if (interrupted)
        return;
      let duration = Number(getComputedStyle(el).transitionDuration.replace(/,.*/, "").replace("s", "")) * 1e3;
      let delay = Number(getComputedStyle(el).transitionDelay.replace(/,.*/, "").replace("s", "")) * 1e3;
      if (duration === 0)
        duration = Number(getComputedStyle(el).animationDuration.replace("s", "")) * 1e3;
      mutateDom(() => {
        stages.before();
      });
      reachedBefore = true;
      requestAnimationFrame(() => {
        if (interrupted)
          return;
        mutateDom(() => {
          stages.end();
        });
        releaseNextTicks();
        setTimeout(el._x_transitioning.finish, duration + delay);
        reachedEnd = true;
      });
    });
  }
  function modifierValue(modifiers, key, fallback) {
    if (modifiers.indexOf(key) === -1)
      return fallback;
    const rawValue = modifiers[modifiers.indexOf(key) + 1];
    if (!rawValue)
      return fallback;
    if (key === "scale") {
      if (isNaN(rawValue))
        return fallback;
    }
    if (key === "duration" || key === "delay") {
      let match = rawValue.match(/([0-9]+)ms/);
      if (match)
        return match[1];
    }
    if (key === "origin") {
      if (["top", "right", "left", "center", "bottom"].includes(modifiers[modifiers.indexOf(key) + 2])) {
        return [rawValue, modifiers[modifiers.indexOf(key) + 2]].join(" ");
      }
    }
    return rawValue;
  }
  var isCloning = false;
  function skipDuringClone(callback, fallback = () => {
  }) {
    return (...args) => isCloning ? fallback(...args) : callback(...args);
  }
  function onlyDuringClone(callback) {
    return (...args) => isCloning && callback(...args);
  }
  var interceptors = [];
  function interceptClone(callback) {
    interceptors.push(callback);
  }
  function cloneNode(from, to) {
    interceptors.forEach((i) => i(from, to));
    isCloning = true;
    dontRegisterReactiveSideEffects(() => {
      initTree(to, (el, callback) => {
        callback(el, () => {
        });
      });
    });
    isCloning = false;
  }
  var isCloningLegacy = false;
  function clone(oldEl, newEl) {
    if (!newEl._x_dataStack)
      newEl._x_dataStack = oldEl._x_dataStack;
    isCloning = true;
    isCloningLegacy = true;
    dontRegisterReactiveSideEffects(() => {
      cloneTree(newEl);
    });
    isCloning = false;
    isCloningLegacy = false;
  }
  function cloneTree(el) {
    let hasRunThroughFirstEl = false;
    let shallowWalker = (el2, callback) => {
      walk(el2, (el3, skip) => {
        if (hasRunThroughFirstEl && isRoot(el3))
          return skip();
        hasRunThroughFirstEl = true;
        callback(el3, skip);
      });
    };
    initTree(el, shallowWalker);
  }
  function dontRegisterReactiveSideEffects(callback) {
    let cache = effect;
    overrideEffect((callback2, el) => {
      let storedEffect = cache(callback2);
      release(storedEffect);
      return () => {
      };
    });
    callback();
    overrideEffect(cache);
  }
  function bind(el, name, value, modifiers = []) {
    if (!el._x_bindings)
      el._x_bindings = reactive({});
    el._x_bindings[name] = value;
    name = modifiers.includes("camel") ? camelCase(name) : name;
    switch (name) {
      case "value":
        bindInputValue(el, value);
        break;
      case "style":
        bindStyles(el, value);
        break;
      case "class":
        bindClasses(el, value);
        break;
      case "selected":
      case "checked":
        bindAttributeAndProperty(el, name, value);
        break;
      default:
        bindAttribute(el, name, value);
        break;
    }
  }
  function bindInputValue(el, value) {
    if (isRadio(el)) {
      if (el.attributes.value === void 0) {
        el.value = value;
      }
    } else if (isCheckbox(el)) {
      if (Number.isInteger(value)) {
        el.value = value;
      } else if (!Array.isArray(value) && typeof value !== "boolean" && ![null, void 0].includes(value)) {
        el.value = String(value);
      } else {
        if (Array.isArray(value)) {
          el.checked = value.some((val) => checkedAttrLooseCompare(val, el.value));
        } else {
          el.checked = !!value;
        }
      }
    } else if (el.tagName === "SELECT") {
      updateSelect(el, value);
    } else {
      if (el.value === value)
        return;
      el.value = value === void 0 ? "" : value;
    }
  }
  function bindClasses(el, value) {
    if (el._x_undoAddedClasses)
      el._x_undoAddedClasses();
    el._x_undoAddedClasses = setClasses(el, value);
  }
  function bindStyles(el, value) {
    if (el._x_undoAddedStyles)
      el._x_undoAddedStyles();
    el._x_undoAddedStyles = setStyles(el, value);
  }
  function bindAttributeAndProperty(el, name, value) {
    bindAttribute(el, name, value);
    setPropertyIfChanged(el, name, value);
  }
  function bindAttribute(el, name, value) {
    if ([null, void 0, false].includes(value) && attributeShouldntBePreservedIfFalsy(name)) {
      el.removeAttribute(name);
    } else {
      if (isBooleanAttr(name))
        value = name;
      setIfChanged(el, name, value);
    }
  }
  function setIfChanged(el, attrName, value) {
    if (el.getAttribute(attrName) != value) {
      el.setAttribute(attrName, value);
    }
  }
  function setPropertyIfChanged(el, propName, value) {
    if (el[propName] !== value) {
      el[propName] = value;
    }
  }
  function updateSelect(el, value) {
    const arrayWrappedValue = [].concat(value).map((value2) => {
      return value2 + "";
    });
    Array.from(el.options).forEach((option) => {
      option.selected = arrayWrappedValue.includes(option.value);
    });
  }
  function camelCase(subject) {
    return subject.toLowerCase().replace(/-(\w)/g, (match, char) => char.toUpperCase());
  }
  function checkedAttrLooseCompare(valueA, valueB) {
    return valueA == valueB;
  }
  function safeParseBoolean(rawValue) {
    if ([1, "1", "true", "on", "yes", true].includes(rawValue)) {
      return true;
    }
    if ([0, "0", "false", "off", "no", false].includes(rawValue)) {
      return false;
    }
    return rawValue ? Boolean(rawValue) : null;
  }
  var booleanAttributes = /* @__PURE__ */ new Set([
    "allowfullscreen",
    "async",
    "autofocus",
    "autoplay",
    "checked",
    "controls",
    "default",
    "defer",
    "disabled",
    "formnovalidate",
    "inert",
    "ismap",
    "itemscope",
    "loop",
    "multiple",
    "muted",
    "nomodule",
    "novalidate",
    "open",
    "playsinline",
    "readonly",
    "required",
    "reversed",
    "selected",
    "shadowrootclonable",
    "shadowrootdelegatesfocus",
    "shadowrootserializable"
  ]);
  function isBooleanAttr(attrName) {
    return booleanAttributes.has(attrName);
  }
  function attributeShouldntBePreservedIfFalsy(name) {
    return !["aria-pressed", "aria-checked", "aria-expanded", "aria-selected"].includes(name);
  }
  function getBinding(el, name, fallback) {
    if (el._x_bindings && el._x_bindings[name] !== void 0)
      return el._x_bindings[name];
    return getAttributeBinding(el, name, fallback);
  }
  function extractProp(el, name, fallback, extract = true) {
    if (el._x_bindings && el._x_bindings[name] !== void 0)
      return el._x_bindings[name];
    if (el._x_inlineBindings && el._x_inlineBindings[name] !== void 0) {
      let binding = el._x_inlineBindings[name];
      binding.extract = extract;
      return dontAutoEvaluateFunctions(() => {
        return evaluate(el, binding.expression);
      });
    }
    return getAttributeBinding(el, name, fallback);
  }
  function getAttributeBinding(el, name, fallback) {
    let attr = el.getAttribute(name);
    if (attr === null)
      return typeof fallback === "function" ? fallback() : fallback;
    if (attr === "")
      return true;
    if (isBooleanAttr(name)) {
      return !![name, "true"].includes(attr);
    }
    return attr;
  }
  function isCheckbox(el) {
    return el.type === "checkbox" || el.localName === "ui-checkbox" || el.localName === "ui-switch";
  }
  function isRadio(el) {
    return el.type === "radio" || el.localName === "ui-radio";
  }
  function debounce(func, wait) {
    let timeout;
    return function() {
      const context = this, args = arguments;
      const later = function() {
        timeout = null;
        func.apply(context, args);
      };
      clearTimeout(timeout);
      timeout = setTimeout(later, wait);
    };
  }
  function throttle(func, limit) {
    let inThrottle;
    return function() {
      let context = this, args = arguments;
      if (!inThrottle) {
        func.apply(context, args);
        inThrottle = true;
        setTimeout(() => inThrottle = false, limit);
      }
    };
  }
  function entangle({ get: outerGet, set: outerSet }, { get: innerGet, set: innerSet }) {
    let firstRun = true;
    let outerHash;
    let innerHash;
    let reference = effect(() => {
      let outer = outerGet();
      let inner = innerGet();
      if (firstRun) {
        innerSet(cloneIfObject(outer));
        firstRun = false;
      } else {
        let outerHashLatest = JSON.stringify(outer);
        let innerHashLatest = JSON.stringify(inner);
        if (outerHashLatest !== outerHash) {
          innerSet(cloneIfObject(outer));
        } else if (outerHashLatest !== innerHashLatest) {
          outerSet(cloneIfObject(inner));
        } else {
        }
      }
      outerHash = JSON.stringify(outerGet());
      innerHash = JSON.stringify(innerGet());
    });
    return () => {
      release(reference);
    };
  }
  function cloneIfObject(value) {
    return typeof value === "object" ? JSON.parse(JSON.stringify(value)) : value;
  }
  function plugin(callback) {
    let callbacks = Array.isArray(callback) ? callback : [callback];
    callbacks.forEach((i) => i(alpine_default));
  }
  var stores = {};
  var isReactive = false;
  function store(name, value) {
    if (!isReactive) {
      stores = reactive(stores);
      isReactive = true;
    }
    if (value === void 0) {
      return stores[name];
    }
    stores[name] = value;
    initInterceptors(stores[name]);
    if (typeof value === "object" && value !== null && value.hasOwnProperty("init") && typeof value.init === "function") {
      stores[name].init();
    }
  }
  function getStores() {
    return stores;
  }
  var binds = {};
  function bind2(name, bindings) {
    let getBindings = typeof bindings !== "function" ? () => bindings : bindings;
    if (name instanceof Element) {
      return applyBindingsObject(name, getBindings());
    } else {
      binds[name] = getBindings;
    }
    return () => {
    };
  }
  function injectBindingProviders(obj) {
    Object.entries(binds).forEach(([name, callback]) => {
      Object.defineProperty(obj, name, {
        get() {
          return (...args) => {
            return callback(...args);
          };
        }
      });
    });
    return obj;
  }
  function applyBindingsObject(el, obj, original) {
    let cleanupRunners = [];
    while (cleanupRunners.length)
      cleanupRunners.pop()();
    let attributes = Object.entries(obj).map(([name, value]) => ({ name, value }));
    let staticAttributes = attributesOnly(attributes);
    attributes = attributes.map((attribute) => {
      if (staticAttributes.find((attr) => attr.name === attribute.name)) {
        return {
          name: `x-bind:${attribute.name}`,
          value: `"${attribute.value}"`
        };
      }
      return attribute;
    });
    directives(el, attributes, original).map((handle) => {
      cleanupRunners.push(handle.runCleanups);
      handle();
    });
    return () => {
      while (cleanupRunners.length)
        cleanupRunners.pop()();
    };
  }
  var datas = {};
  function data(name, callback) {
    datas[name] = callback;
  }
  function injectDataProviders(obj, context) {
    Object.entries(datas).forEach(([name, callback]) => {
      Object.defineProperty(obj, name, {
        get() {
          return (...args) => {
            return callback.bind(context)(...args);
          };
        },
        enumerable: false
      });
    });
    return obj;
  }
  var Alpine = {
    get reactive() {
      return reactive;
    },
    get release() {
      return release;
    },
    get effect() {
      return effect;
    },
    get raw() {
      return raw;
    },
    get transaction() {
      return transaction;
    },
    version: "3.15.12",
    flushAndStopDeferringMutations,
    dontAutoEvaluateFunctions,
    disableEffectScheduling,
    startObservingMutations,
    stopObservingMutations,
    setReactivityEngine,
    onAttributeRemoved,
    onAttributesAdded,
    closestDataStack,
    skipDuringClone,
    onlyDuringClone,
    addRootSelector,
    addInitSelector,
    setErrorHandler,
    interceptClone,
    addScopeToNode,
    deferMutations,
    mapAttributes,
    evaluateLater,
    interceptInit,
    initInterceptors,
    injectMagics,
    setEvaluator,
    setRawEvaluator,
    mergeProxies,
    extractProp,
    findClosest,
    onElRemoved,
    closestRoot,
    destroyTree,
    interceptor,
    transition,
    setStyles,
    mutateDom,
    directive,
    entangle,
    throttle,
    debounce,
    evaluate,
    evaluateRaw,
    initTree,
    nextTick,
    prefixed: prefix,
    prefix: setPrefix,
    plugin,
    magic,
    store,
    start,
    clone,
    cloneNode,
    bound: getBinding,
    $data: scope,
    watch,
    walk,
    data,
    bind: bind2
  };
  var alpine_default = Alpine;
  function makeMap(str, expectsLowerCase) {
    const map = /* @__PURE__ */ Object.create(null);
    const list = str.split(",");
    for (let i = 0; i < list.length; i++) {
      map[list[i]] = true;
    }
    return expectsLowerCase ? (val) => !!map[val.toLowerCase()] : (val) => !!map[val];
  }
  var specialBooleanAttrs = `itemscope,allowfullscreen,formnovalidate,ismap,nomodule,novalidate,readonly`;
  var isBooleanAttr2 = /* @__PURE__ */ makeMap(specialBooleanAttrs + `,async,autofocus,autoplay,controls,default,defer,disabled,hidden,loop,open,required,reversed,scoped,seamless,checked,muted,multiple,selected`);
  var EMPTY_OBJ = true ? Object.freeze({}) : {};
  var EMPTY_ARR = true ? Object.freeze([]) : [];
  var hasOwnProperty = Object.prototype.hasOwnProperty;
  var hasOwn = (val, key) => hasOwnProperty.call(val, key);
  var isArray = Array.isArray;
  var isMap = (val) => toTypeString(val) === "[object Map]";
  var isString = (val) => typeof val === "string";
  var isSymbol = (val) => typeof val === "symbol";
  var isObject = (val) => val !== null && typeof val === "object";
  var objectToString = Object.prototype.toString;
  var toTypeString = (value) => objectToString.call(value);
  var toRawType = (value) => {
    return toTypeString(value).slice(8, -1);
  };
  var isIntegerKey = (key) => isString(key) && key !== "NaN" && key[0] !== "-" && "" + parseInt(key, 10) === key;
  var cacheStringFunction = (fn) => {
    const cache = /* @__PURE__ */ Object.create(null);
    return (str) => {
      const hit = cache[str];
      return hit || (cache[str] = fn(str));
    };
  };
  var camelizeRE = /-(\w)/g;
  var camelize = cacheStringFunction((str) => {
    return str.replace(camelizeRE, (_, c) => c ? c.toUpperCase() : "");
  });
  var hyphenateRE = /\B([A-Z])/g;
  var hyphenate = cacheStringFunction((str) => str.replace(hyphenateRE, "-$1").toLowerCase());
  var capitalize = cacheStringFunction((str) => str.charAt(0).toUpperCase() + str.slice(1));
  var toHandlerKey = cacheStringFunction((str) => str ? `on${capitalize(str)}` : ``);
  var hasChanged = (value, oldValue) => value !== oldValue && (value === value || oldValue === oldValue);
  var targetMap = /* @__PURE__ */ new WeakMap();
  var effectStack = [];
  var activeEffect;
  var ITERATE_KEY = Symbol(true ? "iterate" : "");
  var MAP_KEY_ITERATE_KEY = Symbol(true ? "Map key iterate" : "");
  function isEffect(fn) {
    return fn && fn._isEffect === true;
  }
  function effect2(fn, options = EMPTY_OBJ) {
    if (isEffect(fn)) {
      fn = fn.raw;
    }
    const effect3 = createReactiveEffect(fn, options);
    if (!options.lazy) {
      effect3();
    }
    return effect3;
  }
  function stop(effect3) {
    if (effect3.active) {
      cleanup(effect3);
      if (effect3.options.onStop) {
        effect3.options.onStop();
      }
      effect3.active = false;
    }
  }
  var uid = 0;
  function createReactiveEffect(fn, options) {
    const effect3 = function reactiveEffect() {
      if (!effect3.active) {
        return fn();
      }
      if (!effectStack.includes(effect3)) {
        cleanup(effect3);
        try {
          enableTracking();
          effectStack.push(effect3);
          activeEffect = effect3;
          return fn();
        } finally {
          effectStack.pop();
          resetTracking();
          activeEffect = effectStack[effectStack.length - 1];
        }
      }
    };
    effect3.id = uid++;
    effect3.allowRecurse = !!options.allowRecurse;
    effect3._isEffect = true;
    effect3.active = true;
    effect3.raw = fn;
    effect3.deps = [];
    effect3.options = options;
    return effect3;
  }
  function cleanup(effect3) {
    const { deps } = effect3;
    if (deps.length) {
      for (let i = 0; i < deps.length; i++) {
        deps[i].delete(effect3);
      }
      deps.length = 0;
    }
  }
  var shouldTrack = true;
  var trackStack = [];
  function pauseTracking() {
    trackStack.push(shouldTrack);
    shouldTrack = false;
  }
  function enableTracking() {
    trackStack.push(shouldTrack);
    shouldTrack = true;
  }
  function resetTracking() {
    const last = trackStack.pop();
    shouldTrack = last === void 0 ? true : last;
  }
  function track(target, type, key) {
    if (!shouldTrack || activeEffect === void 0) {
      return;
    }
    let depsMap = targetMap.get(target);
    if (!depsMap) {
      targetMap.set(target, depsMap = /* @__PURE__ */ new Map());
    }
    let dep = depsMap.get(key);
    if (!dep) {
      depsMap.set(key, dep = /* @__PURE__ */ new Set());
    }
    if (!dep.has(activeEffect)) {
      dep.add(activeEffect);
      activeEffect.deps.push(dep);
      if (activeEffect.options.onTrack) {
        activeEffect.options.onTrack({
          effect: activeEffect,
          target,
          type,
          key
        });
      }
    }
  }
  function trigger(target, type, key, newValue, oldValue, oldTarget) {
    const depsMap = targetMap.get(target);
    if (!depsMap) {
      return;
    }
    const effects = /* @__PURE__ */ new Set();
    const add2 = (effectsToAdd) => {
      if (effectsToAdd) {
        effectsToAdd.forEach((effect3) => {
          if (effect3 !== activeEffect || effect3.allowRecurse) {
            effects.add(effect3);
          }
        });
      }
    };
    if (type === "clear") {
      depsMap.forEach(add2);
    } else if (key === "length" && isArray(target)) {
      depsMap.forEach((dep, key2) => {
        if (key2 === "length" || key2 >= newValue) {
          add2(dep);
        }
      });
    } else {
      if (key !== void 0) {
        add2(depsMap.get(key));
      }
      switch (type) {
        case "add":
          if (!isArray(target)) {
            add2(depsMap.get(ITERATE_KEY));
            if (isMap(target)) {
              add2(depsMap.get(MAP_KEY_ITERATE_KEY));
            }
          } else if (isIntegerKey(key)) {
            add2(depsMap.get("length"));
          }
          break;
        case "delete":
          if (!isArray(target)) {
            add2(depsMap.get(ITERATE_KEY));
            if (isMap(target)) {
              add2(depsMap.get(MAP_KEY_ITERATE_KEY));
            }
          }
          break;
        case "set":
          if (isMap(target)) {
            add2(depsMap.get(ITERATE_KEY));
          }
          break;
      }
    }
    const run = (effect3) => {
      if (effect3.options.onTrigger) {
        effect3.options.onTrigger({
          effect: effect3,
          target,
          key,
          type,
          newValue,
          oldValue,
          oldTarget
        });
      }
      if (effect3.options.scheduler) {
        effect3.options.scheduler(effect3);
      } else {
        effect3();
      }
    };
    effects.forEach(run);
  }
  var isNonTrackableKeys = /* @__PURE__ */ makeMap(`__proto__,__v_isRef,__isVue`);
  var builtInSymbols = new Set(Object.getOwnPropertyNames(Symbol).map((key) => Symbol[key]).filter(isSymbol));
  var get2 = /* @__PURE__ */ createGetter();
  var readonlyGet = /* @__PURE__ */ createGetter(true);
  var arrayInstrumentations = /* @__PURE__ */ createArrayInstrumentations();
  function createArrayInstrumentations() {
    const instrumentations = {};
    ["includes", "indexOf", "lastIndexOf"].forEach((key) => {
      instrumentations[key] = function(...args) {
        const arr = toRaw(this);
        for (let i = 0, l = this.length; i < l; i++) {
          track(arr, "get", i + "");
        }
        const res = arr[key](...args);
        if (res === -1 || res === false) {
          return arr[key](...args.map(toRaw));
        } else {
          return res;
        }
      };
    });
    ["push", "pop", "shift", "unshift", "splice"].forEach((key) => {
      instrumentations[key] = function(...args) {
        pauseTracking();
        const res = toRaw(this)[key].apply(this, args);
        resetTracking();
        return res;
      };
    });
    return instrumentations;
  }
  function createGetter(isReadonly = false, shallow = false) {
    return function get3(target, key, receiver) {
      if (key === "__v_isReactive") {
        return !isReadonly;
      } else if (key === "__v_isReadonly") {
        return isReadonly;
      } else if (key === "__v_raw" && receiver === (isReadonly ? shallow ? shallowReadonlyMap : readonlyMap : shallow ? shallowReactiveMap : reactiveMap).get(target)) {
        return target;
      }
      const targetIsArray = isArray(target);
      if (!isReadonly && targetIsArray && hasOwn(arrayInstrumentations, key)) {
        return Reflect.get(arrayInstrumentations, key, receiver);
      }
      const res = Reflect.get(target, key, receiver);
      if (isSymbol(key) ? builtInSymbols.has(key) : isNonTrackableKeys(key)) {
        return res;
      }
      if (!isReadonly) {
        track(target, "get", key);
      }
      if (shallow) {
        return res;
      }
      if (isRef(res)) {
        const shouldUnwrap = !targetIsArray || !isIntegerKey(key);
        return shouldUnwrap ? res.value : res;
      }
      if (isObject(res)) {
        return isReadonly ? readonly(res) : reactive2(res);
      }
      return res;
    };
  }
  var set2 = /* @__PURE__ */ createSetter();
  function createSetter(shallow = false) {
    return function set3(target, key, value, receiver) {
      let oldValue = target[key];
      if (!shallow) {
        value = toRaw(value);
        oldValue = toRaw(oldValue);
        if (!isArray(target) && isRef(oldValue) && !isRef(value)) {
          oldValue.value = value;
          return true;
        }
      }
      const hadKey = isArray(target) && isIntegerKey(key) ? Number(key) < target.length : hasOwn(target, key);
      const result = Reflect.set(target, key, value, receiver);
      if (target === toRaw(receiver)) {
        if (!hadKey) {
          trigger(target, "add", key, value);
        } else if (hasChanged(value, oldValue)) {
          trigger(target, "set", key, value, oldValue);
        }
      }
      return result;
    };
  }
  function deleteProperty(target, key) {
    const hadKey = hasOwn(target, key);
    const oldValue = target[key];
    const result = Reflect.deleteProperty(target, key);
    if (result && hadKey) {
      trigger(target, "delete", key, void 0, oldValue);
    }
    return result;
  }
  function has(target, key) {
    const result = Reflect.has(target, key);
    if (!isSymbol(key) || !builtInSymbols.has(key)) {
      track(target, "has", key);
    }
    return result;
  }
  function ownKeys(target) {
    track(target, "iterate", isArray(target) ? "length" : ITERATE_KEY);
    return Reflect.ownKeys(target);
  }
  var mutableHandlers = {
    get: get2,
    set: set2,
    deleteProperty,
    has,
    ownKeys
  };
  var readonlyHandlers = {
    get: readonlyGet,
    set(target, key) {
      if (true) {
        console.warn(`Set operation on key "${String(key)}" failed: target is readonly.`, target);
      }
      return true;
    },
    deleteProperty(target, key) {
      if (true) {
        console.warn(`Delete operation on key "${String(key)}" failed: target is readonly.`, target);
      }
      return true;
    }
  };
  var toReactive = (value) => isObject(value) ? reactive2(value) : value;
  var toReadonly = (value) => isObject(value) ? readonly(value) : value;
  var toShallow = (value) => value;
  var getProto = (v) => Reflect.getPrototypeOf(v);
  function get$1(target, key, isReadonly = false, isShallow = false) {
    target = target["__v_raw"];
    const rawTarget = toRaw(target);
    const rawKey = toRaw(key);
    if (key !== rawKey) {
      !isReadonly && track(rawTarget, "get", key);
    }
    !isReadonly && track(rawTarget, "get", rawKey);
    const { has: has2 } = getProto(rawTarget);
    const wrap = isShallow ? toShallow : isReadonly ? toReadonly : toReactive;
    if (has2.call(rawTarget, key)) {
      return wrap(target.get(key));
    } else if (has2.call(rawTarget, rawKey)) {
      return wrap(target.get(rawKey));
    } else if (target !== rawTarget) {
      target.get(key);
    }
  }
  function has$1(key, isReadonly = false) {
    const target = this["__v_raw"];
    const rawTarget = toRaw(target);
    const rawKey = toRaw(key);
    if (key !== rawKey) {
      !isReadonly && track(rawTarget, "has", key);
    }
    !isReadonly && track(rawTarget, "has", rawKey);
    return key === rawKey ? target.has(key) : target.has(key) || target.has(rawKey);
  }
  function size(target, isReadonly = false) {
    target = target["__v_raw"];
    !isReadonly && track(toRaw(target), "iterate", ITERATE_KEY);
    return Reflect.get(target, "size", target);
  }
  function add(value) {
    value = toRaw(value);
    const target = toRaw(this);
    const proto = getProto(target);
    const hadKey = proto.has.call(target, value);
    if (!hadKey) {
      target.add(value);
      trigger(target, "add", value, value);
    }
    return this;
  }
  function set$1(key, value) {
    value = toRaw(value);
    const target = toRaw(this);
    const { has: has2, get: get3 } = getProto(target);
    let hadKey = has2.call(target, key);
    if (!hadKey) {
      key = toRaw(key);
      hadKey = has2.call(target, key);
    } else if (true) {
      checkIdentityKeys(target, has2, key);
    }
    const oldValue = get3.call(target, key);
    target.set(key, value);
    if (!hadKey) {
      trigger(target, "add", key, value);
    } else if (hasChanged(value, oldValue)) {
      trigger(target, "set", key, value, oldValue);
    }
    return this;
  }
  function deleteEntry(key) {
    const target = toRaw(this);
    const { has: has2, get: get3 } = getProto(target);
    let hadKey = has2.call(target, key);
    if (!hadKey) {
      key = toRaw(key);
      hadKey = has2.call(target, key);
    } else if (true) {
      checkIdentityKeys(target, has2, key);
    }
    const oldValue = get3 ? get3.call(target, key) : void 0;
    const result = target.delete(key);
    if (hadKey) {
      trigger(target, "delete", key, void 0, oldValue);
    }
    return result;
  }
  function clear() {
    const target = toRaw(this);
    const hadItems = target.size !== 0;
    const oldTarget = true ? isMap(target) ? new Map(target) : new Set(target) : void 0;
    const result = target.clear();
    if (hadItems) {
      trigger(target, "clear", void 0, void 0, oldTarget);
    }
    return result;
  }
  function createForEach(isReadonly, isShallow) {
    return function forEach(callback, thisArg) {
      const observed = this;
      const target = observed["__v_raw"];
      const rawTarget = toRaw(target);
      const wrap = isShallow ? toShallow : isReadonly ? toReadonly : toReactive;
      !isReadonly && track(rawTarget, "iterate", ITERATE_KEY);
      return target.forEach((value, key) => {
        return callback.call(thisArg, wrap(value), wrap(key), observed);
      });
    };
  }
  function createIterableMethod(method, isReadonly, isShallow) {
    return function(...args) {
      const target = this["__v_raw"];
      const rawTarget = toRaw(target);
      const targetIsMap = isMap(rawTarget);
      const isPair = method === "entries" || method === Symbol.iterator && targetIsMap;
      const isKeyOnly = method === "keys" && targetIsMap;
      const innerIterator = target[method](...args);
      const wrap = isShallow ? toShallow : isReadonly ? toReadonly : toReactive;
      !isReadonly && track(rawTarget, "iterate", isKeyOnly ? MAP_KEY_ITERATE_KEY : ITERATE_KEY);
      return {
        next() {
          const { value, done } = innerIterator.next();
          return done ? { value, done } : {
            value: isPair ? [wrap(value[0]), wrap(value[1])] : wrap(value),
            done
          };
        },
        [Symbol.iterator]() {
          return this;
        }
      };
    };
  }
  function createReadonlyMethod(type) {
    return function(...args) {
      if (true) {
        const key = args[0] ? `on key "${args[0]}" ` : ``;
        console.warn(`${capitalize(type)} operation ${key}failed: target is readonly.`, toRaw(this));
      }
      return type === "delete" ? false : this;
    };
  }
  function createInstrumentations() {
    const mutableInstrumentations2 = {
      get(key) {
        return get$1(this, key);
      },
      get size() {
        return size(this);
      },
      has: has$1,
      add,
      set: set$1,
      delete: deleteEntry,
      clear,
      forEach: createForEach(false, false)
    };
    const shallowInstrumentations2 = {
      get(key) {
        return get$1(this, key, false, true);
      },
      get size() {
        return size(this);
      },
      has: has$1,
      add,
      set: set$1,
      delete: deleteEntry,
      clear,
      forEach: createForEach(false, true)
    };
    const readonlyInstrumentations2 = {
      get(key) {
        return get$1(this, key, true);
      },
      get size() {
        return size(this, true);
      },
      has(key) {
        return has$1.call(this, key, true);
      },
      add: createReadonlyMethod("add"),
      set: createReadonlyMethod("set"),
      delete: createReadonlyMethod("delete"),
      clear: createReadonlyMethod("clear"),
      forEach: createForEach(true, false)
    };
    const shallowReadonlyInstrumentations2 = {
      get(key) {
        return get$1(this, key, true, true);
      },
      get size() {
        return size(this, true);
      },
      has(key) {
        return has$1.call(this, key, true);
      },
      add: createReadonlyMethod("add"),
      set: createReadonlyMethod("set"),
      delete: createReadonlyMethod("delete"),
      clear: createReadonlyMethod("clear"),
      forEach: createForEach(true, true)
    };
    const iteratorMethods = ["keys", "values", "entries", Symbol.iterator];
    iteratorMethods.forEach((method) => {
      mutableInstrumentations2[method] = createIterableMethod(method, false, false);
      readonlyInstrumentations2[method] = createIterableMethod(method, true, false);
      shallowInstrumentations2[method] = createIterableMethod(method, false, true);
      shallowReadonlyInstrumentations2[method] = createIterableMethod(method, true, true);
    });
    return [
      mutableInstrumentations2,
      readonlyInstrumentations2,
      shallowInstrumentations2,
      shallowReadonlyInstrumentations2
    ];
  }
  var [mutableInstrumentations, readonlyInstrumentations, shallowInstrumentations, shallowReadonlyInstrumentations] = /* @__PURE__ */ createInstrumentations();
  function createInstrumentationGetter(isReadonly, shallow) {
    const instrumentations = shallow ? isReadonly ? shallowReadonlyInstrumentations : shallowInstrumentations : isReadonly ? readonlyInstrumentations : mutableInstrumentations;
    return (target, key, receiver) => {
      if (key === "__v_isReactive") {
        return !isReadonly;
      } else if (key === "__v_isReadonly") {
        return isReadonly;
      } else if (key === "__v_raw") {
        return target;
      }
      return Reflect.get(hasOwn(instrumentations, key) && key in target ? instrumentations : target, key, receiver);
    };
  }
  var mutableCollectionHandlers = {
    get: /* @__PURE__ */ createInstrumentationGetter(false, false)
  };
  var readonlyCollectionHandlers = {
    get: /* @__PURE__ */ createInstrumentationGetter(true, false)
  };
  function checkIdentityKeys(target, has2, key) {
    const rawKey = toRaw(key);
    if (rawKey !== key && has2.call(target, rawKey)) {
      const type = toRawType(target);
      console.warn(`Reactive ${type} contains both the raw and reactive versions of the same object${type === `Map` ? ` as keys` : ``}, which can lead to inconsistencies. Avoid differentiating between the raw and reactive versions of an object and only use the reactive version if possible.`);
    }
  }
  var reactiveMap = /* @__PURE__ */ new WeakMap();
  var shallowReactiveMap = /* @__PURE__ */ new WeakMap();
  var readonlyMap = /* @__PURE__ */ new WeakMap();
  var shallowReadonlyMap = /* @__PURE__ */ new WeakMap();
  function targetTypeMap(rawType) {
    switch (rawType) {
      case "Object":
      case "Array":
        return 1;
      case "Map":
      case "Set":
      case "WeakMap":
      case "WeakSet":
        return 2;
      default:
        return 0;
    }
  }
  function getTargetType(value) {
    return value["__v_skip"] || !Object.isExtensible(value) ? 0 : targetTypeMap(toRawType(value));
  }
  function reactive2(target) {
    if (target && target["__v_isReadonly"]) {
      return target;
    }
    return createReactiveObject(target, false, mutableHandlers, mutableCollectionHandlers, reactiveMap);
  }
  function readonly(target) {
    return createReactiveObject(target, true, readonlyHandlers, readonlyCollectionHandlers, readonlyMap);
  }
  function createReactiveObject(target, isReadonly, baseHandlers, collectionHandlers, proxyMap) {
    if (!isObject(target)) {
      if (true) {
        console.warn(`value cannot be made reactive: ${String(target)}`);
      }
      return target;
    }
    if (target["__v_raw"] && !(isReadonly && target["__v_isReactive"])) {
      return target;
    }
    const existingProxy = proxyMap.get(target);
    if (existingProxy) {
      return existingProxy;
    }
    const targetType = getTargetType(target);
    if (targetType === 0) {
      return target;
    }
    const proxy = new Proxy(target, targetType === 2 ? collectionHandlers : baseHandlers);
    proxyMap.set(target, proxy);
    return proxy;
  }
  function toRaw(observed) {
    return observed && toRaw(observed["__v_raw"]) || observed;
  }
  function isRef(r) {
    return Boolean(r && r.__v_isRef === true);
  }
  magic("nextTick", () => nextTick);
  magic("dispatch", (el) => dispatch.bind(dispatch, el));
  magic("watch", (el, { evaluateLater: evaluateLater2, cleanup: cleanup2 }) => (key, callback) => {
    let evaluate2 = evaluateLater2(key);
    let getter = () => {
      let value;
      evaluate2((i) => value = i);
      return value;
    };
    let unwatch = watch(getter, callback);
    cleanup2(unwatch);
  });
  magic("store", getStores);
  magic("data", (el) => scope(el));
  magic("root", (el) => closestRoot(el));
  magic("refs", (el) => {
    if (el._x_refs_proxy)
      return el._x_refs_proxy;
    el._x_refs_proxy = mergeProxies(getArrayOfRefObject(el));
    return el._x_refs_proxy;
  });
  function getArrayOfRefObject(el) {
    let refObjects = [];
    findClosest(el, (i) => {
      if (i._x_refs)
        refObjects.push(i._x_refs);
    });
    return refObjects;
  }
  var globalIdMemo = {};
  function findAndIncrementId(name) {
    if (!globalIdMemo[name])
      globalIdMemo[name] = 0;
    return ++globalIdMemo[name];
  }
  function closestIdRoot(el, name) {
    return findClosest(el, (element) => {
      if (element._x_ids && element._x_ids[name])
        return true;
    });
  }
  function setIdRoot(el, name) {
    if (!el._x_ids)
      el._x_ids = {};
    if (!el._x_ids[name])
      el._x_ids[name] = findAndIncrementId(name);
  }
  magic("id", (el, { cleanup: cleanup2 }) => (name, key = null) => {
    let cacheKey = `${name}${key ? `-${key}` : ""}`;
    return cacheIdByNameOnElement(el, cacheKey, cleanup2, () => {
      let root = closestIdRoot(el, name);
      let id = root ? root._x_ids[name] : findAndIncrementId(name);
      return key ? `${name}-${id}-${key}` : `${name}-${id}`;
    });
  });
  interceptClone((from, to) => {
    if (from._x_id) {
      to._x_id = from._x_id;
    }
  });
  function cacheIdByNameOnElement(el, cacheKey, cleanup2, callback) {
    if (!el._x_id)
      el._x_id = {};
    if (el._x_id[cacheKey])
      return el._x_id[cacheKey];
    let output = callback();
    el._x_id[cacheKey] = output;
    cleanup2(() => {
      delete el._x_id[cacheKey];
    });
    return output;
  }
  magic("el", (el) => el);
  warnMissingPluginMagic("Focus", "focus", "focus");
  warnMissingPluginMagic("Persist", "persist", "persist");
  function warnMissingPluginMagic(name, magicName, slug) {
    magic(magicName, (el) => warn(`You can't use [$${magicName}] without first installing the "${name}" plugin here: https://alpinejs.dev/plugins/${slug}`, el));
  }
  directive("modelable", (el, { expression }, { effect: effect3, evaluateLater: evaluateLater2, cleanup: cleanup2 }) => {
    let func = evaluateLater2(expression);
    let innerGet = () => {
      let result;
      func((i) => result = i);
      return result;
    };
    let evaluateInnerSet = evaluateLater2(`${expression} = __placeholder`);
    let innerSet = (val) => evaluateInnerSet(() => {
    }, { scope: { "__placeholder": val } });
    let initialValue = innerGet();
    innerSet(initialValue);
    queueMicrotask(() => {
      if (!el._x_model)
        return;
      el._x_removeModelListeners["default"]();
      let outerGet = el._x_model.get;
      let outerSet = el._x_model.setWithModifiers;
      let releaseEntanglement = entangle({
        get() {
          return outerGet();
        },
        set(value) {
          outerSet(value);
        }
      }, {
        get() {
          return innerGet();
        },
        set(value) {
          innerSet(value);
        }
      });
      cleanup2(releaseEntanglement);
    });
  });
  directive("teleport", (el, { modifiers, expression }, { cleanup: cleanup2 }) => {
    if (el.tagName.toLowerCase() !== "template")
      warn("x-teleport can only be used on a <template> tag", el);
    let target = getTarget(expression);
    let clone2 = el.content.cloneNode(true).firstElementChild;
    el._x_teleport = clone2;
    clone2._x_teleportBack = el;
    el.setAttribute("data-teleport-template", true);
    clone2.setAttribute("data-teleport-target", true);
    if (el._x_forwardEvents) {
      el._x_forwardEvents.forEach((eventName) => {
        clone2.addEventListener(eventName, (e) => {
          e.stopPropagation();
          el.dispatchEvent(new e.constructor(e.type, e));
        });
      });
    }
    addScopeToNode(clone2, {}, el);
    let placeInDom = (clone3, target2, modifiers2) => {
      if (modifiers2.includes("prepend")) {
        target2.parentNode.insertBefore(clone3, target2);
      } else if (modifiers2.includes("append")) {
        target2.parentNode.insertBefore(clone3, target2.nextSibling);
      } else {
        target2.appendChild(clone3);
      }
    };
    mutateDom(() => {
      skipDuringClone(() => {
        placeInDom(clone2, target, modifiers);
        initTree(clone2);
      })();
    });
    el._x_teleportPutBack = () => {
      let target2 = getTarget(expression);
      mutateDom(() => {
        placeInDom(el._x_teleport, target2, modifiers);
      });
    };
    cleanup2(() => mutateDom(() => {
      clone2.remove();
      destroyTree(clone2);
    }));
  });
  var teleportContainerDuringClone = document.createElement("div");
  function getTarget(expression) {
    let target = skipDuringClone(() => {
      return document.querySelector(expression);
    }, () => {
      return teleportContainerDuringClone;
    })();
    if (!target)
      warn(`Cannot find x-teleport element for selector: "${expression}"`);
    return target;
  }
  var handler = () => {
  };
  handler.inline = (el, { modifiers }, { cleanup: cleanup2 }) => {
    modifiers.includes("self") ? el._x_ignoreSelf = true : el._x_ignore = true;
    cleanup2(() => {
      modifiers.includes("self") ? delete el._x_ignoreSelf : delete el._x_ignore;
    });
  };
  directive("ignore", handler);
  directive("effect", skipDuringClone((el, { expression }, { effect: effect3 }) => {
    effect3(evaluateLater(el, expression));
  }));
  function on(el, event, modifiers, callback) {
    let listenerTarget = el;
    let handler4 = (e) => callback(e);
    let options = {};
    let wrapHandler = (callback2, wrapper) => (e) => wrapper(callback2, e);
    if (modifiers.includes("dot"))
      event = dotSyntax(event);
    if (modifiers.includes("camel"))
      event = camelCase2(event);
    if (modifiers.includes("capture"))
      options.capture = true;
    if (modifiers.includes("window"))
      listenerTarget = window;
    if (modifiers.includes("document"))
      listenerTarget = document;
    if (modifiers.includes("passive")) {
      options.passive = modifiers[modifiers.indexOf("passive") + 1] !== "false";
    }
    handler4 = addDebounceOrThrottle(modifiers, handler4);
    if (modifiers.includes("prevent"))
      handler4 = wrapHandler(handler4, (next, e) => {
        e.preventDefault();
        next(e);
      });
    if (modifiers.includes("stop"))
      handler4 = wrapHandler(handler4, (next, e) => {
        e.stopPropagation();
        next(e);
      });
    if (modifiers.includes("once")) {
      handler4 = wrapHandler(handler4, (next, e) => {
        next(e);
        listenerTarget.removeEventListener(event, handler4, options);
      });
    }
    if (modifiers.includes("away") || modifiers.includes("outside")) {
      listenerTarget = document;
      handler4 = wrapHandler(handler4, (next, e) => {
        if (el.contains(e.target))
          return;
        if (e.target.isConnected === false)
          return;
        if (el.offsetWidth < 1 && el.offsetHeight < 1)
          return;
        if (el._x_isShown === false)
          return;
        next(e);
      });
    }
    if (modifiers.includes("self"))
      handler4 = wrapHandler(handler4, (next, e) => {
        e.target === el && next(e);
      });
    if (event === "submit") {
      handler4 = wrapHandler(handler4, (next, e) => {
        if (e.target._x_pendingModelUpdates) {
          e.target._x_pendingModelUpdates.forEach((fn) => fn());
        }
        next(e);
      });
    }
    if (isKeyEvent(event) || isClickEvent(event)) {
      handler4 = wrapHandler(handler4, (next, e) => {
        if (isListeningForASpecificKeyThatHasntBeenPressed(e, modifiers)) {
          return;
        }
        next(e);
      });
    }
    listenerTarget.addEventListener(event, handler4, options);
    return () => {
      listenerTarget.removeEventListener(event, handler4, options);
    };
  }
  function addDebounceOrThrottle(modifiers, handler4) {
    if (modifiers.includes("debounce")) {
      let nextModifier = modifiers[modifiers.indexOf("debounce") + 1] || "invalid-wait";
      let wait = isNumeric(nextModifier.split("ms")[0]) ? Number(nextModifier.split("ms")[0]) : 250;
      handler4 = debounce(handler4, wait);
    }
    if (modifiers.includes("throttle")) {
      let nextModifier = modifiers[modifiers.indexOf("throttle") + 1] || "invalid-wait";
      let wait = isNumeric(nextModifier.split("ms")[0]) ? Number(nextModifier.split("ms")[0]) : 250;
      handler4 = throttle(handler4, wait);
    }
    return handler4;
  }
  function dotSyntax(subject) {
    return subject.replace(/-/g, ".");
  }
  function camelCase2(subject) {
    return subject.toLowerCase().replace(/-(\w)/g, (match, char) => char.toUpperCase());
  }
  function isNumeric(subject) {
    return !Array.isArray(subject) && !isNaN(subject);
  }
  function kebabCase2(subject) {
    if ([" ", "_"].includes(subject))
      return subject;
    return subject.replace(/([a-z])([A-Z])/g, "$1-$2").replace(/[_\s]/, "-").toLowerCase();
  }
  function isKeyEvent(event) {
    return ["keydown", "keyup"].includes(event);
  }
  function isClickEvent(event) {
    return ["contextmenu", "click", "mouse"].some((i) => event.includes(i));
  }
  function isListeningForASpecificKeyThatHasntBeenPressed(e, modifiers) {
    let keyModifiers = modifiers.filter((i) => {
      return !["window", "document", "prevent", "stop", "once", "capture", "self", "away", "outside", "passive", "preserve-scroll", "blur", "change", "lazy"].includes(i);
    });
    if (keyModifiers.includes("debounce")) {
      let debounceIndex = keyModifiers.indexOf("debounce");
      keyModifiers.splice(debounceIndex, isNumeric((keyModifiers[debounceIndex + 1] || "invalid-wait").split("ms")[0]) ? 2 : 1);
    }
    if (keyModifiers.includes("throttle")) {
      let debounceIndex = keyModifiers.indexOf("throttle");
      keyModifiers.splice(debounceIndex, isNumeric((keyModifiers[debounceIndex + 1] || "invalid-wait").split("ms")[0]) ? 2 : 1);
    }
    if (keyModifiers.length === 0)
      return false;
    if (keyModifiers.length === 1 && keyToModifiers(e.key).includes(keyModifiers[0]))
      return false;
    const systemKeyModifiers = ["ctrl", "shift", "alt", "meta", "cmd", "super"];
    const selectedSystemKeyModifiers = systemKeyModifiers.filter((modifier) => keyModifiers.includes(modifier));
    keyModifiers = keyModifiers.filter((i) => !selectedSystemKeyModifiers.includes(i));
    if (selectedSystemKeyModifiers.length > 0) {
      const activelyPressedKeyModifiers = selectedSystemKeyModifiers.filter((modifier) => {
        if (modifier === "cmd" || modifier === "super")
          modifier = "meta";
        return e[`${modifier}Key`];
      });
      if (activelyPressedKeyModifiers.length === selectedSystemKeyModifiers.length) {
        if (isClickEvent(e.type))
          return false;
        if (keyToModifiers(e.key).includes(keyModifiers[0]))
          return false;
      }
    }
    return true;
  }
  function keyToModifiers(key) {
    if (!key)
      return [];
    key = kebabCase2(key);
    let modifierToKeyMap = {
      "ctrl": "control",
      "slash": "/",
      "space": " ",
      "spacebar": " ",
      "cmd": "meta",
      "esc": "escape",
      "up": "arrow-up",
      "down": "arrow-down",
      "left": "arrow-left",
      "right": "arrow-right",
      "period": ".",
      "comma": ",",
      "equal": "=",
      "minus": "-",
      "underscore": "_"
    };
    modifierToKeyMap[key] = key;
    return Object.keys(modifierToKeyMap).map((modifier) => {
      if (modifierToKeyMap[modifier] === key)
        return modifier;
    }).filter((modifier) => modifier);
  }
  directive("model", (el, { modifiers, expression }, { effect: effect3, cleanup: cleanup2 }) => {
    let scopeTarget = el;
    if (modifiers.includes("parent")) {
      scopeTarget = findClosest(el, (element) => element !== el);
    }
    let evaluateGet = evaluateLater(scopeTarget, expression);
    let evaluateSet;
    if (typeof expression === "string") {
      evaluateSet = evaluateLater(scopeTarget, `${expression} = __placeholder`);
    } else if (typeof expression === "function" && typeof expression() === "string") {
      evaluateSet = evaluateLater(scopeTarget, `${expression()} = __placeholder`);
    } else {
      evaluateSet = () => {
      };
    }
    let getValue = () => {
      let result;
      evaluateGet((value) => result = value);
      return isGetterSetter(result) ? result.get() : result;
    };
    let setValue = (value) => {
      let result;
      evaluateGet((value2) => result = value2);
      if (isGetterSetter(result)) {
        result.set(value);
      } else {
        evaluateSet(() => {
        }, {
          scope: { "__placeholder": value }
        });
      }
    };
    if (typeof expression === "string" && el.type === "radio") {
      mutateDom(() => {
        if (!el.hasAttribute("name"))
          el.setAttribute("name", expression);
      });
    }
    let hasChangeModifier = modifiers.includes("change") || modifiers.includes("lazy");
    let hasBlurModifier = modifiers.includes("blur");
    let hasEnterModifier = modifiers.includes("enter");
    let hasExplicitEventModifiers = hasChangeModifier || hasBlurModifier || hasEnterModifier;
    let removeListener;
    if (isCloning) {
      removeListener = () => {
      };
    } else if (hasExplicitEventModifiers) {
      let listeners = [];
      let syncValue = (e) => setValue(getInputValue(el, modifiers, e, getValue()));
      if (hasChangeModifier) {
        listeners.push(on(el, "change", modifiers, syncValue));
      }
      if (hasBlurModifier) {
        listeners.push(on(el, "blur", modifiers, syncValue));
        if (el.form) {
          let form = el.form;
          let syncCallback = () => syncValue({ target: el });
          if (!form._x_pendingModelUpdates)
            form._x_pendingModelUpdates = [];
          form._x_pendingModelUpdates.push(syncCallback);
          cleanup2(() => {
            if (form._x_pendingModelUpdates) {
              form._x_pendingModelUpdates.splice(form._x_pendingModelUpdates.indexOf(syncCallback), 1);
            }
          });
        }
      }
      if (hasEnterModifier) {
        listeners.push(on(el, "keydown", modifiers, (e) => {
          if (e.key === "Enter")
            syncValue(e);
        }));
      }
      removeListener = () => listeners.forEach((remove) => remove());
    } else {
      let event = el.tagName.toLowerCase() === "select" || ["checkbox", "radio"].includes(el.type) ? "change" : "input";
      removeListener = on(el, event, modifiers, (e) => {
        setValue(getInputValue(el, modifiers, e, getValue()));
      });
    }
    if (modifiers.includes("fill")) {
      if ([void 0, null, ""].includes(getValue()) || isCheckbox(el) && Array.isArray(getValue()) || el.tagName.toLowerCase() === "select" && el.multiple) {
        setValue(getInputValue(el, modifiers, { target: el }, getValue()));
      }
    }
    if (!el._x_removeModelListeners)
      el._x_removeModelListeners = {};
    el._x_removeModelListeners["default"] = removeListener;
    cleanup2(() => el._x_removeModelListeners["default"]());
    if (el.form) {
      let removeResetListener = on(el.form, "reset", [], (e) => {
        nextTick(() => el._x_model && el._x_model.set(getInputValue(el, modifiers, { target: el }, getValue())));
      });
      cleanup2(() => removeResetListener());
    }
    el._x_model = {
      get() {
        return getValue();
      },
      set(value) {
        setValue(value);
      },
      setWithModifiers: addDebounceOrThrottle(modifiers, setValue)
    };
    el._x_forceModelUpdate = (value) => {
      if (value === void 0 && typeof expression === "string" && expression.match(/\./))
        value = "";
      mutateDom(() => {
        if (isCheckbox(el)) {
          if (Array.isArray(value)) {
            el.checked = value.some((val) => val == el.value);
          } else {
            el.checked = !!value;
          }
        } else if (isRadio(el)) {
          if (typeof value === "boolean") {
            el.checked = safeParseBoolean(el.value) === value;
          } else {
            el.checked = el.value == value;
          }
        } else {
          bind(el, "value", value);
        }
      });
    };
    effect3(() => {
      let value = getValue();
      if (modifiers.includes("unintrusive") && document.activeElement.isSameNode(el))
        return;
      el._x_forceModelUpdate(value);
    });
  });
  function getInputValue(el, modifiers, event, currentValue) {
    return mutateDom(() => {
      if (event instanceof CustomEvent && event.detail !== void 0)
        return event.detail !== null && event.detail !== void 0 ? event.detail : event.target.value;
      else if (isCheckbox(el)) {
        if (Array.isArray(currentValue)) {
          let newValue = null;
          if (modifiers.includes("number")) {
            newValue = safeParseNumber(event.target.value);
          } else if (modifiers.includes("boolean")) {
            newValue = safeParseBoolean(event.target.value);
          } else {
            newValue = event.target.value;
          }
          return event.target.checked ? currentValue.includes(newValue) ? currentValue : currentValue.concat([newValue]) : currentValue.filter((el2) => !checkedAttrLooseCompare2(el2, newValue));
        } else {
          return event.target.checked;
        }
      } else if (el.tagName.toLowerCase() === "select" && el.multiple) {
        if (modifiers.includes("number")) {
          return Array.from(event.target.selectedOptions).map((option) => {
            let rawValue = option.value || option.text;
            return safeParseNumber(rawValue);
          });
        } else if (modifiers.includes("boolean")) {
          return Array.from(event.target.selectedOptions).map((option) => {
            let rawValue = option.value || option.text;
            return safeParseBoolean(rawValue);
          });
        }
        return Array.from(event.target.selectedOptions).map((option) => {
          return option.value || option.text;
        });
      } else {
        let newValue;
        if (isRadio(el)) {
          if (event.target.checked) {
            newValue = event.target.value;
          } else {
            newValue = currentValue;
          }
        } else {
          newValue = event.target.value;
        }
        if (modifiers.includes("number")) {
          return safeParseNumber(newValue);
        } else if (modifiers.includes("boolean")) {
          return safeParseBoolean(newValue);
        } else if (modifiers.includes("trim")) {
          return newValue.trim();
        } else {
          return newValue;
        }
      }
    });
  }
  function safeParseNumber(rawValue) {
    let number = rawValue ? parseFloat(rawValue) : null;
    return isNumeric2(number) ? number : rawValue;
  }
  function checkedAttrLooseCompare2(valueA, valueB) {
    return valueA == valueB;
  }
  function isNumeric2(subject) {
    return !Array.isArray(subject) && !isNaN(subject);
  }
  function isGetterSetter(value) {
    return value !== null && typeof value === "object" && typeof value.get === "function" && typeof value.set === "function";
  }
  directive("cloak", (el) => queueMicrotask(() => mutateDom(() => el.removeAttribute(prefix("cloak")))));
  addInitSelector(() => `[${prefix("init")}]`);
  directive("init", skipDuringClone((el, { expression }, { evaluate: evaluate2 }) => {
    if (typeof expression === "string") {
      return !!expression.trim() && evaluate2(expression, {}, false);
    }
    return evaluate2(expression, {}, false);
  }));
  directive("text", (el, { expression }, { effect: effect3, evaluateLater: evaluateLater2 }) => {
    let evaluate2 = evaluateLater2(expression);
    effect3(() => {
      evaluate2((value) => {
        mutateDom(() => {
          el.textContent = value;
        });
      });
    });
  });
  directive("html", (el, { expression }, { effect: effect3, evaluateLater: evaluateLater2 }) => {
    let evaluate2 = evaluateLater2(expression);
    effect3(() => {
      evaluate2((value) => {
        mutateDom(() => {
          el.innerHTML = value ?? "";
          el._x_ignoreSelf = true;
          initTree(el);
          delete el._x_ignoreSelf;
        });
      });
    });
  });
  mapAttributes(startingWith(":", into(prefix("bind:"))));
  var handler2 = (el, { value, modifiers, expression, original }, { effect: effect3, cleanup: cleanup2 }) => {
    if (!value) {
      let bindingProviders = {};
      injectBindingProviders(bindingProviders);
      let getBindings = evaluateLater(el, expression);
      getBindings((bindings) => {
        applyBindingsObject(el, bindings, original);
      }, { scope: bindingProviders });
      return;
    }
    if (value === "key")
      return storeKeyForXFor(el, expression);
    if (el._x_inlineBindings && el._x_inlineBindings[value] && el._x_inlineBindings[value].extract) {
      return;
    }
    let evaluate2 = evaluateLater(el, expression);
    effect3(() => evaluate2((result) => {
      if (result === void 0 && typeof expression === "string" && expression.match(/\./)) {
        result = "";
      }
      mutateDom(() => bind(el, value, result, modifiers));
    }));
    cleanup2(() => {
      el._x_undoAddedClasses && el._x_undoAddedClasses();
      el._x_undoAddedStyles && el._x_undoAddedStyles();
    });
  };
  handler2.inline = (el, { value, modifiers, expression }) => {
    if (!value)
      return;
    if (!el._x_inlineBindings)
      el._x_inlineBindings = {};
    el._x_inlineBindings[value] = { expression, extract: false };
  };
  directive("bind", handler2);
  function storeKeyForXFor(el, expression) {
    el._x_keyExpression = expression;
  }
  addRootSelector(() => `[${prefix("data")}]`);
  directive("data", (el, { expression }, { cleanup: cleanup2 }) => {
    if (shouldSkipRegisteringDataDuringClone(el))
      return;
    expression = expression === "" ? "{}" : expression;
    let magicContext = {};
    injectMagics(magicContext, el);
    let dataProviderContext = {};
    injectDataProviders(dataProviderContext, magicContext);
    let data2 = evaluate(el, expression, { scope: dataProviderContext });
    if (data2 === void 0 || data2 === true)
      data2 = {};
    injectMagics(data2, el);
    let reactiveData = reactive(data2);
    initInterceptors(reactiveData);
    let undo = addScopeToNode(el, reactiveData);
    reactiveData["init"] && evaluate(el, reactiveData["init"]);
    cleanup2(() => {
      reactiveData["destroy"] && evaluate(el, reactiveData["destroy"]);
      undo();
    });
  });
  interceptClone((from, to) => {
    if (from._x_dataStack) {
      to._x_dataStack = from._x_dataStack;
      to.setAttribute("data-has-alpine-state", true);
    }
  });
  function shouldSkipRegisteringDataDuringClone(el) {
    if (!isCloning)
      return false;
    if (isCloningLegacy)
      return true;
    return el.hasAttribute("data-has-alpine-state");
  }
  directive("show", (el, { modifiers, expression }, { effect: effect3 }) => {
    let evaluate2 = evaluateLater(el, expression);
    if (!el._x_doHide)
      el._x_doHide = () => {
        mutateDom(() => {
          el.style.setProperty("display", "none", modifiers.includes("important") ? "important" : void 0);
        });
      };
    if (!el._x_doShow)
      el._x_doShow = () => {
        mutateDom(() => {
          if (el.style.length === 1 && el.style.display === "none") {
            el.removeAttribute("style");
          } else {
            el.style.removeProperty("display");
          }
        });
      };
    let hide = () => {
      el._x_doHide();
      el._x_isShown = false;
    };
    let show = () => {
      el._x_doShow();
      el._x_isShown = true;
    };
    let clickAwayCompatibleShow = () => setTimeout(show);
    let toggle = once((value) => value ? show() : hide(), (value) => {
      if (typeof el._x_toggleAndCascadeWithTransitions === "function") {
        el._x_toggleAndCascadeWithTransitions(el, value, show, hide);
      } else {
        value ? clickAwayCompatibleShow() : hide();
      }
    });
    let oldValue;
    let firstTime = true;
    effect3(() => evaluate2((value) => {
      if (!firstTime && value === oldValue)
        return;
      if (modifiers.includes("immediate"))
        value ? clickAwayCompatibleShow() : hide();
      toggle(value);
      oldValue = value;
      firstTime = false;
    }));
  });
  directive("for", (el, { expression }, { effect: effect3, cleanup: cleanup2 }) => {
    let iteratorNames = parseForExpression(expression);
    let evaluateItems = evaluateLater(el, iteratorNames.items);
    let evaluateKey = evaluateLater(el, el._x_keyExpression || "index");
    el._x_lookup = /* @__PURE__ */ new Map();
    effect3(() => loop(el, iteratorNames, evaluateItems, evaluateKey));
    cleanup2(() => {
      el._x_lookup.forEach((el2) => mutateDom(() => {
        destroyTree(el2);
        el2.remove();
      }));
      delete el._x_lookup;
    });
  });
  function refreshScope(scope2) {
    return (newScope) => {
      Object.entries(newScope).forEach(([key, value]) => {
        scope2[key] = value;
      });
    };
  }
  function loop(templateEl, iteratorNames, evaluateItems, evaluateKey) {
    evaluateItems((items) => {
      if (isNumeric3(items))
        items = Array.from({ length: items }, (_, i) => i + 1);
      if (items === void 0 || items === null)
        items = [];
      if (items instanceof Set)
        items = Array.from(items);
      if (items instanceof Map)
        items = Array.from(items);
      let oldLookup = templateEl._x_lookup;
      let lookup = /* @__PURE__ */ new Map();
      templateEl._x_lookup = lookup;
      let hasStringKeys = isObject2(items);
      let scopeEntries = Object.entries(items).map(([index, item]) => {
        if (!hasStringKeys)
          index = parseInt(index);
        let scope2 = getIterationScopeVariables(iteratorNames, item, index, items);
        let key;
        evaluateKey((innerKey) => {
          if (typeof innerKey === "object")
            warn("x-for key cannot be an object, it must be a string or an integer", templateEl);
          if (oldLookup.has(innerKey)) {
            lookup.set(innerKey, oldLookup.get(innerKey));
            oldLookup.delete(innerKey);
          }
          key = innerKey;
        }, { scope: { index, ...scope2 } });
        return [key, scope2];
      });
      mutateDom(() => {
        oldLookup.forEach((el) => {
          destroyTree(el);
          el.remove();
        });
        let added = /* @__PURE__ */ new Set();
        let prev = templateEl;
        scopeEntries.forEach(([key, scope2]) => {
          if (lookup.has(key)) {
            let el = lookup.get(key);
            el._x_refreshXForScope(scope2);
            if (prev.nextElementSibling !== el) {
              if (prev.nextElementSibling)
                el.replaceWith(prev.nextElementSibling);
              prev.after(el);
            }
            prev = el;
            if (el._x_currentIfEl) {
              if (el.nextElementSibling !== el._x_currentIfEl)
                prev.after(el._x_currentIfEl);
              prev = el._x_currentIfEl;
            }
            return;
          }
          if (templateEl.content.children.length > 1)
            warn("x-for templates require a single root element, additional elements will be ignored.", templateEl);
          let clone2 = document.importNode(templateEl.content, true).firstElementChild;
          let reactiveScope = reactive(scope2);
          addScopeToNode(clone2, reactiveScope, templateEl);
          clone2._x_refreshXForScope = refreshScope(reactiveScope);
          lookup.set(key, clone2);
          added.add(clone2);
          prev.after(clone2);
          prev = clone2;
        });
        skipDuringClone(() => added.forEach((clone2) => initTree(clone2)))();
      });
    });
  }
  function parseForExpression(expression) {
    let forIteratorRE = /,([^,\}\]]*)(?:,([^,\}\]]*))?$/;
    let stripParensRE = /^\s*\(|\)\s*$/g;
    let forAliasRE = /([\s\S]*?)\s+(?:in|of)\s+([\s\S]*)/;
    let inMatch = expression.match(forAliasRE);
    if (!inMatch)
      return;
    let res = {};
    res.items = inMatch[2].trim();
    let item = inMatch[1].replace(stripParensRE, "").trim();
    let iteratorMatch = item.match(forIteratorRE);
    if (iteratorMatch) {
      res.item = item.replace(forIteratorRE, "").trim();
      res.index = iteratorMatch[1].trim();
      if (iteratorMatch[2]) {
        res.collection = iteratorMatch[2].trim();
      }
    } else {
      res.item = item;
    }
    return res;
  }
  function getIterationScopeVariables(iteratorNames, item, index, items) {
    let scopeVariables = {};
    if (/^\[.*\]$/.test(iteratorNames.item) && Array.isArray(item)) {
      let names = iteratorNames.item.replace("[", "").replace("]", "").split(",").map((i) => i.trim());
      names.forEach((name, i) => {
        scopeVariables[name] = item[i];
      });
    } else if (/^\{.*\}$/.test(iteratorNames.item) && !Array.isArray(item) && typeof item === "object") {
      let names = iteratorNames.item.replace("{", "").replace("}", "").split(",").map((i) => i.trim());
      names.forEach((name) => {
        scopeVariables[name] = item[name];
      });
    } else {
      scopeVariables[iteratorNames.item] = item;
    }
    if (iteratorNames.index)
      scopeVariables[iteratorNames.index] = index;
    if (iteratorNames.collection)
      scopeVariables[iteratorNames.collection] = items;
    return scopeVariables;
  }
  function isNumeric3(subject) {
    return typeof subject !== "object" && !isNaN(subject);
  }
  function isObject2(subject) {
    return typeof subject === "object" && !Array.isArray(subject);
  }
  function handler3() {
  }
  handler3.inline = (el, { expression }, { cleanup: cleanup2 }) => {
    let root = closestRoot(el);
    if (!root)
      return;
    if (!root._x_refs)
      root._x_refs = {};
    root._x_refs[expression] = el;
    cleanup2(() => delete root._x_refs[expression]);
  };
  directive("ref", handler3);
  directive("if", (el, { expression }, { effect: effect3, cleanup: cleanup2 }) => {
    if (el.tagName.toLowerCase() !== "template")
      warn("x-if can only be used on a <template> tag", el);
    let evaluate2 = evaluateLater(el, expression);
    let show = () => {
      if (el._x_currentIfEl)
        return el._x_currentIfEl;
      let clone2 = el.content.cloneNode(true).firstElementChild;
      addScopeToNode(clone2, {}, el);
      mutateDom(() => {
        el.after(clone2);
        skipDuringClone(() => initTree(clone2))();
      });
      el._x_currentIfEl = clone2;
      el._x_undoIf = () => {
        mutateDom(() => {
          destroyTree(clone2);
          clone2.remove();
        });
        delete el._x_currentIfEl;
      };
      return clone2;
    };
    let hide = () => {
      if (!el._x_undoIf)
        return;
      el._x_undoIf();
      delete el._x_undoIf;
    };
    effect3(() => evaluate2((value) => {
      value ? show() : hide();
    }));
    cleanup2(() => el._x_undoIf && el._x_undoIf());
  });
  directive("id", (el, { expression }, { evaluate: evaluate2 }) => {
    let names = evaluate2(expression);
    names.forEach((name) => setIdRoot(el, name));
  });
  interceptClone((from, to) => {
    if (from._x_ids) {
      to._x_ids = from._x_ids;
    }
  });
  mapAttributes(startingWith("@", into(prefix("on:"))));
  directive("on", skipDuringClone((el, { value, modifiers, expression }, { cleanup: cleanup2 }) => {
    let evaluate2 = expression ? evaluateLater(el, expression) : () => {
    };
    if (el.tagName.toLowerCase() === "template") {
      if (!el._x_forwardEvents)
        el._x_forwardEvents = [];
      if (!el._x_forwardEvents.includes(value))
        el._x_forwardEvents.push(value);
    }
    let removeListener = on(el, value, modifiers, (e) => {
      evaluate2(() => {
      }, { scope: { "$event": e }, params: [e] });
    });
    cleanup2(() => removeListener());
  }));
  warnMissingPluginDirective("Collapse", "collapse", "collapse");
  warnMissingPluginDirective("Intersect", "intersect", "intersect");
  warnMissingPluginDirective("Focus", "trap", "focus");
  warnMissingPluginDirective("Mask", "mask", "mask");
  function warnMissingPluginDirective(name, directiveName, slug) {
    directive(directiveName, (el) => warn(`You can't use [x-${directiveName}] without first installing the "${name}" plugin here: https://alpinejs.dev/plugins/${slug}`, el));
  }
  alpine_default.setEvaluator(normalEvaluator);
  alpine_default.setRawEvaluator(normalRawEvaluator);
  alpine_default.setReactivityEngine({ reactive: reactive2, effect: effect2, release: stop, raw: toRaw });
  var src_default = alpine_default;
  var module_default = src_default;

  // js/components/color_picker.js
  var HEX_COLOR = /^#[0-9A-Fa-f]{6}$/;
  var normalizeColor = (value) => {
    if (!value)
      return value;
    const trimmed = value.trim();
    return trimmed.startsWith("#") ? trimmed.toUpperCase() : `#${trimmed}`.toUpperCase();
  };
  var dispatchInput = (input) => {
    input.dispatchEvent(new Event("input", { bubbles: true }));
    input.dispatchEvent(new Event("change", { bubbles: true }));
  };
  var ExLingoColorPicker = {
    mounted() {
      this.picker = this.el.querySelector("[data-color-picker]");
      this.text = this.el.querySelector("[data-color-text]");
      if (!this.picker || !this.text)
        return;
      this.syncTextFromPicker = this.syncTextFromPicker.bind(this);
      this.syncPickerFromText = this.syncPickerFromText.bind(this);
      this.picker.addEventListener("input", this.syncTextFromPicker);
      this.picker.addEventListener("change", this.syncTextFromPicker);
      this.text.addEventListener("input", this.syncPickerFromText);
      this.text.addEventListener("change", this.syncPickerFromText);
    },
    destroyed() {
      if (!this.picker || !this.text)
        return;
      this.picker.removeEventListener("input", this.syncTextFromPicker);
      this.picker.removeEventListener("change", this.syncTextFromPicker);
      this.text.removeEventListener("input", this.syncPickerFromText);
      this.text.removeEventListener("change", this.syncPickerFromText);
    },
    syncTextFromPicker() {
      const value = normalizeColor(this.picker.value);
      if (!HEX_COLOR.test(value))
        return;
      this.text.value = value;
      dispatchInput(this.text);
    },
    syncPickerFromText() {
      const value = normalizeColor(this.text.value);
      this.text.value = value;
      if (HEX_COLOR.test(value)) {
        this.picker.value = value;
      }
    }
  };

  // js/components/glossary_capture.js
  var ExLingoGlossaryCapture = {
    mounted() {
      this.handleClick = () => {
        const root = this.el.closest("[data-glossary-scope]") || this.el.closest("form") || this.el.parentElement || this.el;
        const sourceTerm = readSourceSelection(root);
        const targetTerm = readTargetSelection(root);
        this.pushEventTo(this.el, "open_glossary_for_selection", {
          source_term: sourceTerm,
          target_term: targetTerm
        });
      };
      this.el.addEventListener("click", this.handleClick);
    },
    destroyed() {
      if (this.handleClick) {
        this.el.removeEventListener("click", this.handleClick);
      }
    }
  };
  function readSourceSelection(root) {
    const sourceEl = root.querySelector("[data-glossary-source]");
    if (!sourceEl) {
      return "";
    }
    const selection = window.getSelection();
    if (selection && selection.rangeCount > 0) {
      const range = selection.getRangeAt(0);
      if (sourceEl.contains(range.commonAncestorContainer)) {
        const marked = selection.toString().trim();
        if (marked.length > 0) {
          return marked;
        }
      }
    }
    return "";
  }
  function readTargetSelection(root) {
    const targets = root.querySelectorAll("[data-glossary-target]");
    for (const targetEl of targets) {
      if (typeof targetEl.selectionStart !== "number") {
        continue;
      }
      if (targetEl.selectionStart === targetEl.selectionEnd) {
        continue;
      }
      const marked = targetEl.value.substring(targetEl.selectionStart, targetEl.selectionEnd).trim();
      if (marked.length > 0) {
        return marked;
      }
    }
    return "";
  }

  // js/components/inline_edit.js
  var ExLingoInlineEdit = {
    mounted() {
      this.handleKeydown = (event) => {
        if (event.key === "Enter" && (event.metaKey || event.ctrlKey)) {
          event.preventDefault();
          this.saveAndAdvance();
        }
      };
      this.el.addEventListener("keydown", this.handleKeydown);
    },
    destroyed() {
      if (this.handleKeydown) {
        this.el.removeEventListener("keydown", this.handleKeydown);
      }
    },
    saveAndAdvance() {
      const root = this.el.closest("table") || document;
      const inputs = Array.from(root.querySelectorAll("[data-inline-input]"));
      const index = inputs.indexOf(this.el);
      this.el.blur();
      const next = index >= 0 ? inputs[index + 1] : null;
      if (next) {
        next.focus();
        if (typeof next.setSelectionRange === "function") {
          const end = next.value.length;
          next.setSelectionRange(end, end);
        }
      }
    }
  };

  // js/components/list_context.js
  var DEFAULT_CONTEXT_PREFIXES = ["search", "page", "filter[", "sort["];
  var parseJson = (value, fallback) => {
    if (!value)
      return fallback;
    try {
      return JSON.parse(value);
    } catch (_error) {
      return fallback;
    }
  };
  var contextPrefixes = (value) => {
    const parsed = parseJson(value, DEFAULT_CONTEXT_PREFIXES);
    if (Array.isArray(parsed) && parsed.every((entry) => typeof entry === "string")) {
      return parsed;
    }
    return DEFAULT_CONTEXT_PREFIXES;
  };
  var hasExplicitContext = (prefixes) => {
    const url = new URL(window.location.href);
    return [...url.searchParams.keys()].some((key) => prefixes.some((prefix2) => key === prefix2 || key.startsWith(prefix2)));
  };
  var isEmptyContext = (context) => !context || typeof context !== "object" || Object.values(context).every((value) => {
    if (Array.isArray(value))
      return value.length === 0;
    if (value && typeof value === "object")
      return Object.keys(value).length === 0;
    return value === null || value === void 0 || value === "";
  });
  var uiStorageKey = (storageKey) => `${storageKey}:ui`;
  var readUiState = (storageKey) => parseJson(window.localStorage.getItem(uiStorageKey(storageKey)), {});
  var writeUiState = (storageKey, attrs) => {
    if (!storageKey)
      return;
    window.localStorage.setItem(uiStorageKey(storageKey), JSON.stringify({
      ...readUiState(storageKey),
      ...attrs,
      updatedAt: Date.now()
    }));
  };
  var visibleListItem = (root, itemId) => {
    if (!itemId)
      return null;
    return [...root.querySelectorAll("[data-list-item-id]")].find((item) => item.dataset.listItemId === String(itemId));
  };
  var removeHighlight = (root) => {
    root.querySelectorAll(".ex-lingo-list-highlight").forEach((item) => item.classList.remove("ex-lingo-list-highlight"));
  };
  var highlightedItemIdFromUrl = () => {
    const url = new URL(window.location.href);
    return url.searchParams.get("highlight_message_id") || url.searchParams.get("edit_message_id");
  };
  var ExLingoListContext = {
    mounted() {
      this.restoreAttempted = false;
      this.scrollRestored = false;
      this.restoreScrollAfterUpdate = false;
      this.contextPrefixes = contextPrefixes(this.el.dataset.contextPrefixes);
      this.trackItemClick = this.trackItemClick.bind(this);
      this.trackScroll = this.trackScroll.bind(this);
      this.el.addEventListener("click", this.trackItemClick, true);
      window.addEventListener("scroll", this.trackScroll, { passive: true });
      if (!this.maybeRestore()) {
        this.syncStorage();
        this.restoreUiState();
      }
    },
    updated() {
      const restoreScroll = this.restoreScrollAfterUpdate;
      this.restoreScrollAfterUpdate = false;
      this.syncStorage();
      this.restoreUiState({ restoreScroll });
    },
    destroyed() {
      this.el.removeEventListener("click", this.trackItemClick, true);
      window.removeEventListener("scroll", this.trackScroll);
    },
    syncStorage() {
      const storageKey = this.el.dataset.storageKey;
      if (!storageKey)
        return;
      const context = parseJson(this.el.dataset.listContext, {});
      if (isEmptyContext(context)) {
        window.localStorage.removeItem(storageKey);
        return;
      }
      window.localStorage.setItem(storageKey, JSON.stringify(context));
    },
    maybeRestore() {
      if (this.restoreAttempted)
        return false;
      this.restoreAttempted = true;
      if (hasExplicitContext(this.contextPrefixes)) {
        return false;
      }
      const storageKey = this.el.dataset.storageKey;
      if (!storageKey)
        return false;
      const context = parseJson(window.localStorage.getItem(storageKey), {});
      if (isEmptyContext(context))
        return false;
      this.restoreScrollAfterUpdate = true;
      this.pushEvent("restore-list-context", context);
      return true;
    },
    trackItemClick(event) {
      const item = event.target.closest("[data-list-item-id]");
      if (!item || !this.el.contains(item))
        return;
      const storageKey = this.el.dataset.storageKey;
      if (!storageKey)
        return;
      writeUiState(storageKey, {
        lastItemId: item.dataset.listItemId,
        scrollY: window.scrollY,
        scrollX: window.scrollX
      });
    },
    trackScroll() {
      if (this.scrollTimer)
        return;
      this.scrollTimer = window.requestAnimationFrame(() => {
        this.scrollTimer = null;
        const storageKey = this.el.dataset.storageKey;
        if (!storageKey)
          return;
        writeUiState(storageKey, {
          scrollY: window.scrollY,
          scrollX: window.scrollX
        });
      });
    },
    restoreUiState(options = {}) {
      const { restoreScroll = true } = options;
      const storageKey = this.el.dataset.storageKey;
      if (!storageKey)
        return;
      const uiState = readUiState(storageKey);
      const highlightedItemId = highlightedItemIdFromUrl() || uiState.lastItemId;
      removeHighlight(this.el);
      const item = visibleListItem(this.el, highlightedItemId);
      if (item)
        item.classList.add("ex-lingo-list-highlight");
      if (restoreScroll && !this.scrollRestored && Number.isFinite(uiState.scrollY)) {
        this.scrollRestored = true;
        window.requestAnimationFrame(() => {
          window.scrollTo(uiState.scrollX || 0, uiState.scrollY);
        });
      }
    }
  };

  // js/components/save_indicator.js
  var RESET_DELAY_MS = 1500;
  var ExLingoSaveIndicator = {
    mounted() {
      this.applyState();
    },
    updated() {
      this.applyState();
    },
    destroyed() {
      if (this.timer) {
        clearTimeout(this.timer);
      }
      if (this.flashTimer) {
        clearTimeout(this.flashTimer);
      }
    },
    applyState() {
      const state = this.el.dataset.saveState;
      if (this.timer) {
        clearTimeout(this.timer);
        this.timer = null;
      }
      this.el.classList.remove("opacity-0");
      if (state === "saved" || state === "error") {
        if (state === "saved") {
          this.flashRow();
        }
        this.timer = setTimeout(() => {
          this.el.classList.add("opacity-0");
        }, RESET_DELAY_MS);
      }
    },
    flashRow() {
      const row = this.el.closest("[data-inline-row]");
      if (!row) {
        return;
      }
      if (this.flashTimer) {
        clearTimeout(this.flashTimer);
      }
      row.classList.add("ex-lingo-list-highlight");
      this.flashTimer = setTimeout(() => {
        row.classList.remove("ex-lingo-list-highlight");
        this.flashTimer = null;
      }, RESET_DELAY_MS);
    }
  };

  // js/components/shared/select.js
  var Select = {
    mounted() {
      this.el.addEventListener("selected-change", (event) => {
        this.pushEventTo(event.detail.id, "update", event.detail);
      });
      this.handleEvent("close-selected", (data2) => {
        const fieldId = data2.id;
        const element = document.querySelector(fieldId);
        element.value = data2.value;
        element.dispatchEvent(new Event("input", { bubbles: true }));
        if (!element)
          return;
        if (data2.id !== `#${this.el.id}`)
          return;
        element.dispatchEvent(new CustomEvent("reset"));
      });
    }
  };

  // js/components/shared/toggle.js
  var Toggle = {
    mounted() {
      this.el.addEventListener("toggle-change", (event) => {
        const fieldId = event.detail.id;
        const element = document.querySelector(fieldId);
        element.value = event.detail.state;
        element.dispatchEvent(new Event("input", { bubbles: true }));
        this.pushEventTo(event.detail.id, "update", event.detail);
      });
    }
  };

  // ../deps/cognit/assets/js/ui/core/factory.js
  var ComponentRegistry = class {
    constructor() {
      this.registry = /* @__PURE__ */ new Map();
    }
    register(type, ComponentClass) {
      this.registry.set(type, ComponentClass);
      return this;
    }
    create(type, el, hookContext) {
      const ComponentClass = this.registry.get(type);
      if (!ComponentClass) {
        console.error(`Component type '${type}' not registered`);
        return null;
      }
      const instance = new ComponentClass(el, hookContext);
      instance.setupEvents();
      return instance;
    }
  };
  var registry = new ComponentRegistry();

  // ../deps/cognit/assets/js/ui/core/hook.js
  var SaladUIHook = {
    mounted() {
      this.initComponent();
      this.setupServerEvents();
    },
    initComponent() {
      const el = this.el;
      const componentType = el.getAttribute("data-component");
      if (!componentType) {
        console.error("SaladUI: Component element is missing data-component attribute");
        return;
      }
      this.component = registry.create(componentType, el, this);
    },
    setupServerEvents() {
      if (!this.component)
        return;
      this.handleEvent("saladui:command", ({ command, params = {}, target }) => {
        if (target && target !== this.el.id)
          return;
        if (this.component) {
          this.component.handleCommand(command, params);
        }
      });
    },
    updated() {
      if (this.component) {
        const partsStale = this.component.allParts.some((p) => !p.isConnected);
        if (partsStale) {
          this.component.destroy();
          this.component = null;
          this.initComponent();
          this.component?.onDomUpdate();
        } else {
          this.component.onDomUpdate();
        }
      }
    },
    destroyed() {
      this.component?.destroy();
      this.component = null;
    }
  };

  // ../deps/cognit/assets/js/ui/core/state-machine.js
  var StateMachine = class {
    constructor(stateConfig, initialState, options) {
      this.stateConfig = stateConfig;
      this.state = initialState || "idle";
      this.previousState = null;
      this.options = options || {};
    }
    transition(event, params = {}) {
      const currentStateConfig = this.stateConfig[this.state];
      if (!currentStateConfig)
        return false;
      const transition2 = currentStateConfig.transitions?.[event];
      if (!transition2)
        return false;
      const nextState = this.determineNextState(transition2, params);
      if (!nextState)
        return false;
      const prevState = this.state;
      this.executeTransition(prevState, nextState, params);
      return true;
    }
    determineNextState(transition2, params) {
      if (typeof transition2 === "string") {
        return transition2;
      } else if (typeof transition2 === "function") {
        return transition2(params);
      }
      return null;
    }
    executeTransition(prevState, nextState, params = {}) {
      if (!this.options.validCheck())
        return;
      this.executeStateHandler(prevState, "exit", params);
      this.previousState = prevState;
      this.state = nextState;
      let callbackResult;
      if (typeof this.options.onStateChanged === "function") {
        callbackResult = this.options.onStateChanged(prevState, nextState, params);
      }
      if (callbackResult && typeof callbackResult.then === "function") {
        callbackResult.then(() => {
          if (!this.options.validCheck())
            return;
          this.executeStateHandler(nextState, "enter", params);
        }).catch((error2) => {
          console.error("Animation promise rejected:", error2);
          this.executeStateHandler(nextState, "enter", params);
        });
      } else {
        this.executeStateHandler(nextState, "enter", params);
      }
    }
    executeStateHandler(stateName, handlerType, params) {
      const stateConfig = this.stateConfig[stateName];
      if (!stateConfig)
        return;
      const handler4 = stateConfig[handlerType];
      if (typeof handler4 === "function") {
        handler4(params);
      }
    }
    hasStateChanged() {
      return this.state !== this.previousState;
    }
  };
  var state_machine_default = StateMachine;

  // ../deps/cognit/assets/js/ui/core/utils.js
  function animateTransition(animConfig, targetElement) {
    if (!animConfig || !targetElement) {
      return Promise.resolve();
    }
    const { animation, duration = 200 } = animConfig;
    const animationClasses = (animation || ["", "", ""]).map((item) => typeof item === "string" ? item.split(/\s+/) : []);
    return executeAnimation(targetElement, {
      animation: animationClasses,
      duration
    });
  }
  function executeAnimation(targetElement, animOptions) {
    return new Promise((resolve) => {
      const { animation, duration } = animOptions;
      let [transitionRun, transitionStart, transitionEnd] = animation || [
        [],
        [],
        []
      ];
      addOrRemoveClasses(targetElement, transitionStart, [].concat(transitionRun).concat(transitionEnd));
      window.requestAnimationFrame(() => {
        addOrRemoveClasses(targetElement, transitionRun, []);
        window.requestAnimationFrame(() => addOrRemoveClasses(targetElement, transitionEnd, transitionStart));
      });
      setTimeout(() => {
        addOrRemoveClasses(targetElement, [], [].concat(transitionRun).concat(transitionStart).concat(transitionEnd));
        resolve();
      }, duration);
    });
  }
  function addOrRemoveClasses(targetElement, addClasses = [], removeClasses = []) {
    if (!targetElement)
      return;
    if (addClasses.length > 0) {
      targetElement.classList.add(...addClasses.filter(Boolean));
    }
    if (removeClasses.length > 0) {
      targetElement.classList.remove(...removeClasses.filter(Boolean));
    }
  }
  var FilterResult = {
    IGNORE_AND_CONTINUE: 0,
    SELECT_AND_CONTINUE: 1,
    IGNORE_AND_SKIP: -1
  };
  function queryDOM(root, filterFunction, options = { breadthFirst: true }) {
    if (!(root instanceof Node))
      throw new TypeError("Root must be a DOM node");
    if (typeof filterFunction !== "function")
      throw new TypeError("Filter must be a function");
    const result = [];
    const nodes = [...root.children];
    const getNext = options.breadthFirst !== false ? () => nodes.shift() : () => nodes.pop();
    while (nodes.length > 0) {
      const current = getNext();
      if (!(current instanceof Element))
        continue;
      const filterResult = filterFunction(current);
      if (filterResult === FilterResult.SELECT_AND_CONTINUE) {
        result.push(current);
        addChildren(current, nodes);
      } else if (filterResult === FilterResult.IGNORE_AND_CONTINUE) {
        addChildren(current, nodes);
      }
    }
    return result;
  }
  function addChildren(element, collection) {
    for (let i = 0; i < element.children.length; i++) {
      collection.push(element.children[i]);
    }
  }

  // ../deps/cognit/assets/js/ui/core/component.js
  var Component = class {
    constructor(el, options) {
      const { hookContext, initialState = "idle", ignoreItems = true } = options;
      this.el = el;
      this.hook = hookContext;
      this.config = {
        preventDefaultKeys: []
      };
      this.initialState = initialState;
      this.eventConfig = {};
      this.componentConfig = {};
      this.hiddenConfig = {};
      this.ariaConfig = {};
      this.destroyed = false;
      this.parseOptions();
      this.disabled = !!this.options.disabled;
      this.initEventMappings();
      this.initConfig();
      this.initStateMachine(this.componentConfig.stateMachine, this.initialState);
      this.ariaManager = new AriaManager(this, this.ariaConfig);
      this.allParts = this.queryParts();
      if (ignoreItems) {
        this.allParts = this.allParts.filter((element) => !element.dataset.part.startsWith("item") && !element.dataset.part.endsWith("-item"));
      }
      this.updateUI();
      this.updatePartsVisibility();
      this.partMouseEventHandlers = /* @__PURE__ */ new Map();
      this.keyEventHandlers = /* @__PURE__ */ new Map();
    }
    parseOptions() {
      try {
        const optionsString = this.el.getAttribute("data-options");
        this.options = optionsString ? JSON.parse(optionsString) : {};
        this.initialState = this.el.getAttribute("data-state") || this.initialState;
      } catch (error2) {
        console.error("SaladUI: Error parsing component options:", error2);
        this.options = {};
      }
    }
    queryParts() {
      return queryDOM(this.el, (node) => {
        if (!node.dataset?.part)
          return 0;
        if (node.getAttribute("phx-hook") != null)
          return -1;
        return 1;
      }).concat([this.el]);
    }
    initEventMappings() {
      this.onClientCommand = this.onClientCommand.bind(this);
      try {
        const mappingsString = this.el.getAttribute("data-event-mappings");
        this.eventMappings = mappingsString ? JSON.parse(mappingsString) : {};
      } catch (error2) {
        console.error("SaladUI: Error parsing event mappings:", error2);
        this.eventMappings = {};
      }
    }
    initConfig() {
      this.componentConfig = this.getComponentConfig();
      if (!this.componentConfig.stateMachine) {
        this.componentConfig.stateMachine = {
          idle: {
            enter: () => {
            },
            exit: () => {
            },
            transitions: {}
          }
        };
      } else {
        this.componentConfig.stateMachine = this.bindStateHandlers(this.componentConfig.stateMachine);
      }
      this.eventConfig = this.componentConfig.events || {};
      this.hiddenConfig = this.componentConfig.hiddenConfig || {};
      this.ariaConfig = this.componentConfig.ariaConfig || {};
    }
    getComponentConfig() {
      throw new Error("getComponentConfig() must be implemented in subclass");
    }
    initStateMachine(stateMachineConfig, initialState) {
      this.stateMachine = new state_machine_default(stateMachineConfig, initialState, {
        onStateChanged: this.onStateChanged.bind(this),
        validCheck: () => !this.destroyed
      });
    }
    onClientCommand(event) {
      const { command, params } = event.detail;
      if (command) {
        this.handleCommand(command, params);
      }
    }
    onStateChanged(prevState, nextState, params) {
      if (this.destroyed)
        return;
      const transitionName = `${prevState}_to_${nextState}`;
      const animConfig = this.options.animations?.[transitionName];
      this.updateUI();
      if (!animConfig) {
        this.updatePartsVisibility(nextState);
        return null;
      }
      const targetElement = animConfig.target_part ? this.getPart(animConfig.target_part) : this.el;
      return animateTransition(animConfig, targetElement).then(() => {
        if (this.destroyed)
          return;
        this.updatePartsVisibility(nextState);
      });
    }
    bindStateHandlers(stateMachineConfig) {
      Object.keys(stateMachineConfig).forEach((stateName) => {
        const stateConfig = stateMachineConfig[stateName];
        ["enter", "exit"].forEach((handlerName) => {
          if (typeof stateConfig[handlerName] === "string") {
            const methodName = stateConfig[handlerName];
            if (typeof this[methodName] === "function") {
              stateConfig[handlerName] = this[methodName].bind(this);
            } else {
              console.warn(`Method ${methodName} not found for ${handlerName} handler in state ${stateName}`);
            }
          }
        });
      });
      return stateMachineConfig;
    }
    setupEvents() {
      if (this.eventSetupCompleted) {
        this.removeAllEvents();
      }
      this.el.addEventListener("salad_ui:command", this.onClientCommand);
      this.el.addEventListener("click", this.handleActionClick.bind(this));
      this.setupKeyEventHandlers();
      this.setupMouseEventHandlers();
      this.setupComponentEvents();
      this.eventSetupCompleted = true;
    }
    handleActionClick(event) {
      const actionElement = event.target.closest("[data-action]");
      if (!actionElement)
        return;
      const action = actionElement.getAttribute("data-action");
      this.transition(action, {
        originalEvent: event,
        target: actionElement
      });
    }
    setupComponentEvents() {
    }
    setupKeyEventHandlers() {
      Object.keys(this.eventConfig).forEach((stateName) => {
        const stateEvents = this.eventConfig[stateName];
        if (!stateEvents || !stateEvents.keyMap)
          return;
        const boundHandler = (event) => {
          if (stateName == "_all" || this.stateMachine?.state === stateName) {
            const key = event.key;
            const action = stateEvents.keyMap[key];
            if (action) {
              this.executeHandler(action, event);
              if (this.config.preventDefaultKeys.includes(key)) {
                event.preventDefault();
              }
            }
          }
        };
        const element = this.getPart(stateEvents.keyEventTarget) || this.el;
        element.addEventListener("keydown", boundHandler);
        this.keyEventHandlers.set(element, boundHandler);
      });
    }
    setupMouseEventHandlers() {
      Object.keys(this.eventConfig).forEach((stateName) => {
        const stateEvents = this.eventConfig[stateName];
        if (!stateEvents || !stateEvents.mouseMap)
          return;
        const mouseMap = stateEvents.mouseMap;
        Object.keys(mouseMap).forEach((partName) => {
          const partElements = this.getAllParts(partName);
          if (!partElements.length)
            return;
          Object.keys(mouseMap[partName]).forEach((eventType) => {
            const handlerAction = mouseMap[partName][eventType];
            const boundHandler = (event) => {
              const currentState = this.stateMachine.state;
              if (currentState === stateName) {
                this.executeHandler(handlerAction, event);
              }
            };
            partElements.forEach((element) => {
              element.addEventListener(eventType, boundHandler);
              if (!this.partMouseEventHandlers.has(element)) {
                this.partMouseEventHandlers.set(element, /* @__PURE__ */ new Map());
              }
              const elementHandlers = this.partMouseEventHandlers.get(element);
              if (!elementHandlers.has(eventType)) {
                elementHandlers.set(eventType, []);
              }
              elementHandlers.get(eventType).push(boundHandler);
            });
          });
        });
      });
    }
    removeKeyEventHandlers() {
      if (this.keyEventHandlers) {
        this.keyEventHandlers.forEach((handler4, element) => {
          element.removeEventListener("keydown", handler4);
        });
        this.keyEventHandlers.clear();
      }
    }
    removeMouseEventListeners() {
      if (this.partMouseEventHandlers) {
        this.partMouseEventHandlers.forEach((eventHandlers, element) => {
          eventHandlers.forEach((handlers, eventType) => {
            handlers.forEach((handler4) => {
              element.removeEventListener(eventType, handler4);
            });
          });
        });
        this.partMouseEventHandlers.clear();
      }
    }
    executeHandler(handler4, event, targetElement) {
      if (typeof handler4 === "function") {
        handler4.call(this, event);
      } else if (typeof handler4 === "string") {
        if (typeof this[handler4] === "function") {
          this[handler4](event);
        } else {
          this.transition(handler4, {
            originalEvent: event,
            target: targetElement
          });
        }
      }
    }
    transition(event, params = {}) {
      if (this.destroyed)
        return;
      return this.stateMachine.transition(event, params);
    }
    updateUI(params = {}) {
      const currentState = this.stateMachine.state;
      this.allParts.forEach((el) => el.setAttribute("data-state", currentState));
      this.el.setAttribute("data-state", currentState);
      this.ariaManager.applyAriaAttributes(currentState);
    }
    updatePartsVisibility() {
      const currentState = this.stateMachine.state;
      const stateVisibility = this.hiddenConfig[currentState];
      if (!stateVisibility)
        return;
      Object.entries(stateVisibility).forEach(([partName, hidden]) => {
        const partElements = this.getAllParts(partName);
        partElements.forEach((element) => {
          if (element) {
            element.hidden = hidden;
          }
        });
      });
    }
    getPart(name) {
      return this.allParts.find((part) => part.dataset.part === name);
    }
    getAllParts(name) {
      return this.allParts.filter((part) => part.dataset.part === name);
    }
    getPartId(partName) {
      const part = this.getPart(partName);
      if (!part)
        return null;
      if (!part.id) {
        part.id = `${this.el.id}-${partName}`;
      }
      return part.id;
    }
    pushEvent(clientEvent, payload = {}, context) {
      if (!this.hook || !this.hook.pushEventTo)
        return;
      const eventHandler = this.eventMappings[clientEvent];
      const el = context || this.el;
      if (eventHandler) {
        if (typeof eventHandler === "string") {
          const fullPayload = {
            ...payload,
            componentId: el.id,
            component: el.getAttribute("data-component")
          };
          this.hook.pushEventTo(this.el, eventHandler, fullPayload);
        } else {
          this.hook.liveSocket.execJS(this.el, JSON.stringify(eventHandler));
        }
      }
    }
    get state() {
      return this.stateMachine.state;
    }
    get previousState() {
      return this.stateMachine.previousState;
    }
    removeAllEvents() {
      this.el.removeEventListener("salad_ui:command", this.onClientCommand);
      this.el.removeEventListener("click", this.handleActionClick);
      this.removeKeyEventHandlers();
      this.removeMouseEventListeners();
    }
    destroy() {
      this.beforeDestroy();
      this.removeAllEvents();
      this.ariaManager = null;
      this.stateMachine = null;
      this.el = null;
      this.hook = null;
      this.options = null;
      this.componentConfig = null;
      this.destroyed = true;
    }
    beforeDestroy() {
    }
    onDomUpdate() {
      this.parseOptions();
      this.initEventMappings();
      this.updatePartsVisibility();
      this.updateUI();
    }
    handleCommand(command, params = {}) {
      return this.transition(command, params);
    }
    trigger(event, params = {}) {
      return this.transition(event, params);
    }
  };
  var AriaManager = class {
    constructor(component, ariaConfig) {
      this.component = component;
      this.ariaConfig = ariaConfig || {};
    }
    applyAriaAttributes(currentState) {
      if (!this.ariaConfig)
        return;
      Object.entries(this.ariaConfig).forEach(([partName, states]) => {
        const parts = this.component.getAllParts(partName);
        if (!parts || parts.length === 0)
          return;
        parts.forEach((part, index) => {
          this.applyGlobalAriaAttributes(part, states);
          this.applyStateSpecificAriaAttributes(part, states, currentState);
        });
      });
    }
    applyGlobalAriaAttributes(part, states) {
      if (!states.all)
        return;
      Object.entries(states.all).forEach(([attr, value]) => {
        this.applyAriaAttribute(part, attr, value);
      });
    }
    applyStateSpecificAriaAttributes(part, states, currentState) {
      const stateConfig = states[currentState];
      if (!stateConfig)
        return;
      Object.entries(stateConfig).forEach(([attr, value]) => {
        this.applyAriaAttribute(part, attr, value);
      });
    }
    applyAriaAttribute(part, attr, value) {
      const resolvedValue = typeof value === "function" ? value.call(this.component, part) : value;
      if (resolvedValue === null || resolvedValue === void 0)
        return;
      if (attr === "role") {
        part.setAttribute("role", resolvedValue);
      } else {
        part.setAttribute(`aria-${attr}`, resolvedValue);
      }
    }
  };
  var component_default = Component;

  // ../deps/cognit/assets/js/ui/index.js
  function register(type, ComponentClass) {
    registry.register(type, ComponentClass);
  }
  var SaladUI = {
    Component: component_default,
    register,
    SaladUIHook
  };
  var ui_default = SaladUI;

  // ../deps/cognit/assets/js/ui/core/focus-trap.js
  var FocusTrap = class {
    constructor(element, options = {}) {
      this.element = element;
      this.options = {
        focusableSelector: 'a[href], button:not([disabled]), input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])',
        ...options
      };
      this.previouslyFocused = null;
      this.active = false;
      this.handleKeyDown = this.handleKeyDown.bind(this);
    }
    activate() {
      if (this.active)
        return;
      this.previouslyFocused = document.activeElement;
      this.active = true;
      this.element.addEventListener("keydown", this.handleKeyDown);
      this.setInitialFocus();
    }
    deactivate() {
      if (!this.active)
        return;
      this.element.removeEventListener("keydown", this.handleKeyDown);
      if (this.previouslyFocused && this.previouslyFocused.focus && this.isElementInViewport(this.previouslyFocused)) {
        setTimeout(() => {
          this.previouslyFocused.focus();
          this.previouslyFocused = null;
        }, 0);
      }
      this.active = false;
    }
    setInitialFocus() {
      const focusableElements = this.getFocusableElements();
      setTimeout(() => {
        if (focusableElements.length > 0) {
          const autoFocusEl = this.element.querySelector("[autofocus]");
          const initialFocusEl = autoFocusEl || focusableElements[0];
          initialFocusEl.focus();
        } else {
          this.element.setAttribute("tabindex", "-1");
          this.element.focus();
        }
      }, 50);
    }
    handleKeyDown(event) {
      if (event.key === "Tab") {
        const focusableElements = this.getFocusableElements();
        if (focusableElements.length === 0)
          return;
        const firstElement = focusableElements[0];
        const lastElement = focusableElements[focusableElements.length - 1];
        const activeElement = document.activeElement;
        if (!event.shiftKey && activeElement === lastElement) {
          firstElement.focus();
          event.preventDefault();
        } else if (event.shiftKey && activeElement === firstElement) {
          lastElement.focus();
          event.preventDefault();
        }
      }
    }
    getFocusableElements() {
      return Array.from(this.element.querySelectorAll(this.options.focusableSelector));
    }
    isElementInViewport(element) {
      if (!element || !document.body.contains(element)) {
        return false;
      }
      const rect = element.getBoundingClientRect();
      return rect.top >= 0 && rect.left >= 0 && rect.bottom <= (window.innerHeight || document.documentElement.clientHeight) && rect.right <= (window.innerWidth || document.documentElement.clientWidth);
    }
    destroy() {
      this.deactivate();
      this.element = null;
      this.options = null;
      this.previouslyFocused = null;
    }
  };
  var focus_trap_default = FocusTrap;

  // ../deps/cognit/assets/js/ui/core/click-outside.js
  var ClickOutsideMonitor = class {
    constructor(elements, callback, options = {}) {
      this.elements = Array.isArray(elements) ? elements : [elements];
      this.callback = callback;
      this.options = {
        trackTouch: true,
        filter: null,
        ...options
      };
      this.active = false;
      this.handleClick = this.handleClick.bind(this);
      this.handleTouchEnd = this.handleTouchEnd.bind(this);
    }
    start() {
      if (this.active)
        return;
      document.addEventListener("click", this.handleClick, true);
      if (this.options.trackTouch) {
        document.addEventListener("touchend", this.handleTouchEnd, true);
      }
      this.active = true;
    }
    stop() {
      if (!this.active)
        return;
      document.removeEventListener("click", this.handleClick, true);
      if (this.options.trackTouch) {
        document.removeEventListener("touchend", this.handleTouchEnd, true);
      }
      this.active = false;
    }
    handleClick(event) {
      this.checkOutsideClick(event);
    }
    handleTouchEnd(event) {
      this.checkOutsideClick(event);
    }
    checkOutsideClick(event) {
      if (!this.active || !this.callback)
        return;
      if (this.options.filter && !this.options.filter(event)) {
        return;
      }
      const target = event.target;
      const isOutside = !this.elements.some((element) => {
        return element && (element === target || element.contains(target));
      });
      if (isOutside) {
        this.callback(event);
      }
    }
    updateElements(elements) {
      this.elements = Array.isArray(elements) ? elements : [elements];
    }
    destroy() {
      this.stop();
      this.elements = null;
      this.callback = null;
      this.options = null;
    }
  };
  var click_outside_default = ClickOutsideMonitor;

  // ../deps/cognit/assets/js/ui/components/dialog.js
  var DialogComponent = class extends component_default {
    constructor(el, hookContext) {
      const initialState = el.dataset.state || "closed";
      super(el, { hookContext, initialState });
      this.root = this.el;
      this.content = this.getPart("content");
      this.contentPanel = this.getPart("content-panel");
      this.config.preventDefaultKeys = ["Escape"];
      this.setupEvents();
      this.transition(this.el.dataset.open == "true" ? "open" : "close");
    }
    getComponentConfig() {
      return {
        stateMachine: {
          closed: {
            enter: "onClosedEnter",
            transitions: {
              open: "open"
            }
          },
          open: {
            enter: "onOpenEnter",
            transitions: {
              close: "closed"
            }
          }
        },
        events: {
          closed: {
            keyMap: {}
          },
          open: {
            keyMap: {
              Escape: "close"
            }
          }
        },
        hiddenConfig: {
          closed: {
            content: true
          },
          open: {
            content: false
          }
        },
        ariaConfig: {
          content: {
            all: {
              role: "dialog"
            },
            open: {
              hidden: "false",
              modal: "true"
            },
            closed: {
              hidden: "true"
            }
          },
          "content-panel": {
            open: {
              labelledby: () => this.getPartId("title"),
              describedby: () => this.getPartId("description")
            }
          },
          "close-trigger": {
            all: {
              label: "Close dialog"
            }
          }
        }
      };
    }
    setupComponentEvents() {
      super.setupComponentEvents();
      if (this.options.closeOnOutsideClick) {
        this.setupOutsideClickDetection();
      }
    }
    setupOutsideClickDetection() {
      this.clickOutsideMonitor = new click_outside_default([this.contentPanel], (event) => {
        if (event.target === this.content || event.target.dataset.part === "overlay") {
          this.transition("close");
        }
      });
    }
    onClosedEnter() {
      if (this.focusTrap) {
        this.focusTrap.deactivate();
      }
      if (this.clickOutsideMonitor) {
        this.clickOutsideMonitor.stop();
      }
      this.pushEvent("closed");
    }
    onOpenEnter() {
      this.el.focus();
      if (!this.focusTrap) {
        this.focusTrap = new focus_trap_default(this.contentPanel);
      }
      this.focusTrap.activate();
      if (this.clickOutsideMonitor) {
        this.clickOutsideMonitor.start();
      }
      this.pushEvent("opened");
    }
    beforeDestroy() {
      this.focusTrap?.destroy();
      this.focusTrap = null;
      this.clickOutsideMonitor?.destroy();
      this.clickOutsideMonitor = null;
    }
  };
  ui_default.register("dialog", DialogComponent);

  // ../deps/cognit/assets/js/ui/core/collection.js
  var Collection = class {
    constructor(options = {}) {
      this.options = {
        type: "single",
        defaultValue: null,
        value: null,
        getItemValue: (item) => item.value,
        isItemDisabled: (item) => item.disabled,
        ...options
      };
      this.items = [];
      this.focusedItem = null;
      this.values = [];
      if (this.options.value !== null && this.options.value !== void 0) {
        this.setValues(this.options.value);
      } else if (this.options.defaultValue !== null && this.options.defaultValue !== void 0) {
        this.setValues(this.options.defaultValue);
      }
    }
    reset() {
      this.items = [];
      this.values = Array.isArray(this.options.defaultValue) ? [...this.options.defaultValue] : this.options.defaultValue ? [this.options.defaultValue] : [];
      this.focusedItem = null;
    }
    setValues(values) {
      if (values === void 0 || values === null) {
        this.values = Array.isArray(this.options.defaultValue) ? [...this.options.defaultValue] : this.options.defaultValue ? [this.options.defaultValue] : [];
        return;
      }
      if (this.options.type === "single") {
        this.values = Array.isArray(values) ? [values[0]] : [values];
      } else {
        this.values = Array.isArray(values) ? [...values] : [values];
      }
      this.updateSelectedStates();
    }
    getValue(asArray = false) {
      if (this.options.type === "multiple" || asArray) {
        return [...this.values];
      }
      return this.values.length > 0 ? this.values[0] : null;
    }
    add(item) {
      const itemValue = this.options.getItemValue(item);
      const isSelected = this.values.includes(itemValue);
      const collectionItem = {
        instance: item,
        value: itemValue,
        focused: false,
        selected: isSelected
      };
      this.items.push(collectionItem);
      if (isSelected && typeof item.handleEvent === "function") {
        item.handleEvent("select");
      }
      return collectionItem;
    }
    remove(itemInstance) {
      const index = this.items.findIndex((item) => item.instance === itemInstance);
      if (index >= 0) {
        const [removedItem] = this.items.splice(index, 1);
        if (this.focusedItem === removedItem) {
          this.focusedItem = null;
        }
        if (removedItem.selected) {
          this.values = this.values.filter((value) => value !== removedItem.value);
        }
      }
    }
    clear() {
      this.items = [];
      this.focusedItem = null;
    }
    getItemByInstance(itemInstance) {
      return this.items.find((item) => item.instance === itemInstance) || null;
    }
    getItemByValue(value) {
      return this.items.find((item) => item.value === value) || null;
    }
    getItem(direction, referenceItem = null, loop2 = true) {
      const enabledItems = this.items.filter((item) => !this.options.isItemDisabled(item.instance));
      if (enabledItems.length === 0)
        return null;
      switch (direction) {
        case "first":
          return enabledItems[0];
        case "last":
          return enabledItems[enabledItems.length - 1];
        case "next":
          if (!referenceItem)
            return this.getItem("first");
          const nextIndex = enabledItems.indexOf(referenceItem) + 1;
          if (nextIndex >= enabledItems.length) {
            return loop2 ? enabledItems[0] : null;
          }
          return enabledItems[nextIndex];
        case "prev":
        case "previous":
          if (!referenceItem)
            return this.getItem("last");
          const currentIndex = enabledItems.indexOf(referenceItem);
          if (currentIndex === -1)
            return enabledItems[enabledItems.length - 1];
          const prevIndex = currentIndex - 1;
          if (prevIndex < 0) {
            return loop2 ? enabledItems[enabledItems.length - 1] : null;
          }
          return enabledItems[prevIndex];
        default:
          return null;
      }
    }
    focus(item) {
      if (!item || this.options.isItemDisabled(item.instance))
        return false;
      if (this.focusedItem) {
        this.focusedItem.focused = false;
        if (typeof this.focusedItem.instance.handleEvent === "function") {
          this.focusedItem.instance.handleEvent("blur");
        }
      }
      this.focusedItem = item;
      item.focused = true;
      if (typeof item.instance.handleEvent === "function") {
        return item.instance.handleEvent("focus") !== false;
      }
      return true;
    }
    select(item) {
      if (!item || this.options.isItemDisabled(item.instance))
        return false;
      const isMultiple = this.options.type === "multiple";
      if (!isMultiple && item.selected && this.values.length === 1) {
        return true;
      }
      if (!isMultiple) {
        this.items.forEach((existingItem) => {
          if (existingItem !== item && existingItem.selected) {
            existingItem.selected = false;
            if (typeof existingItem.instance.handleEvent === "function") {
              existingItem.instance.handleEvent("unselect");
            }
          }
        });
        this.values = [];
      }
      if (item.selected) {
        item.selected = false;
        this.values = this.values.filter((value) => value !== item.value);
        if (typeof item.instance.handleEvent === "function") {
          return item.instance.handleEvent("unselect") !== false;
        }
      } else {
        item.selected = true;
        this.values.push(item.value);
        if (typeof item.instance.handleEvent === "function") {
          return item.instance.handleEvent("select") !== false;
        }
      }
      return true;
    }
    updateSelectedStates() {
      this.items.forEach((item) => {
        const shouldBeSelected = this.values.includes(item.value);
        if (item.selected !== shouldBeSelected) {
          item.selected = shouldBeSelected;
          if (typeof item.instance.handleEvent === "function") {
            item.instance.handleEvent(shouldBeSelected ? "select" : "unselect");
          }
        }
      });
    }
    isValueSelected(value) {
      return this.values.includes(value);
    }
    each(callback) {
      this.items.forEach((item) => callback(item.instance));
    }
  };
  var collection_default = Collection;

  // ../deps/cognit/assets/js/ui/core/positioner.js
  var Positioner = class {
    static calculate(element, reference, options = {}) {
      const {
        placement = "bottom",
        alignment = "center",
        container = document.body,
        flip = true,
        alignOffset = 0,
        sideOffset = 8
      } = options;
      const referenceRect = reference.getBoundingClientRect();
      const elementRect = {
        width: element.offsetWidth,
        height: element.offsetHeight
      };
      let containerRect;
      if (container === document.body) {
        containerRect = {
          top: 0,
          right: window.innerWidth,
          bottom: window.innerHeight,
          left: 0,
          width: window.innerWidth,
          height: window.innerHeight
        };
      } else {
        containerRect = container.getBoundingClientRect();
      }
      let { x, y } = this.getBasePosition(placement, alignment, elementRect, referenceRect, alignOffset, sideOffset);
      let actualPlacement = placement;
      if (flip) {
        const flippedPlacement = this.getFlippedPlacement(placement, { x, y, width: elementRect.width, height: elementRect.height }, containerRect);
        if (flippedPlacement !== placement) {
          actualPlacement = flippedPlacement;
          const flippedPosition = this.getBasePosition(flippedPlacement, alignment, elementRect, referenceRect, alignOffset, sideOffset);
          x = flippedPosition.x;
          y = flippedPosition.y;
        }
      }
      return {
        x,
        y,
        placement: actualPlacement
      };
    }
    static applyPosition(element, x, y) {
      element.style.position = "fixed";
      const containingBlock = this.getContainingBlock(element);
      if (containingBlock) {
        const rect = containingBlock.getBoundingClientRect();
        x -= rect.left;
        y -= rect.top;
      }
      element.style.top = y + "px";
      element.style.left = x + "px";
      element.style.margin = "0";
    }
    static getContainingBlock(element) {
      let parent = element.parentElement;
      while (parent && parent !== document.documentElement) {
        const style = window.getComputedStyle(parent);
        if (style.transform !== "none" || style.perspective !== "none" || style.filter !== "none" || style.willChange === "transform" || style.willChange === "perspective" || style.willChange === "filter") {
          return parent;
        }
        parent = parent.parentElement;
      }
      return null;
    }
    static getBasePosition(placement, alignment, elementRect, referenceRect, alignOffset = 0, sideOffset = 8) {
      let x = 0;
      let y = 0;
      switch (placement) {
        case "top":
          y = referenceRect.top - elementRect.height - sideOffset;
          break;
        case "right":
          x = referenceRect.right + sideOffset;
          y = referenceRect.top;
          break;
        case "bottom":
          y = referenceRect.bottom + sideOffset;
          break;
        case "left":
          x = referenceRect.left - elementRect.width - sideOffset;
          y = referenceRect.top;
          break;
      }
      switch (alignment) {
        case "start":
          if (placement === "top" || placement === "bottom") {
            x = referenceRect.left + alignOffset;
          } else {
            y = referenceRect.top + alignOffset;
          }
          break;
        case "center":
          if (placement === "top" || placement === "bottom") {
            x = referenceRect.left + referenceRect.width / 2 - elementRect.width / 2 + alignOffset;
          } else {
            y = referenceRect.top + referenceRect.height / 2 - elementRect.height / 2 + alignOffset;
          }
          break;
        case "end":
          if (placement === "top" || placement === "bottom") {
            x = referenceRect.right - elementRect.width + alignOffset;
          } else {
            y = referenceRect.bottom - elementRect.height + alignOffset;
          }
          break;
      }
      return { x, y };
    }
    static getFlippedPlacement(placement, elementCoords, containerRect) {
      const { x, y, width, height } = elementCoords;
      const overflowTop = y < containerRect.top;
      const overflowRight = x + width > containerRect.right;
      const overflowBottom = y + height > containerRect.bottom;
      const overflowLeft = x < containerRect.left;
      switch (placement) {
        case "top":
          if (overflowTop && !overflowBottom) {
            return "bottom";
          }
          break;
        case "right":
          if (overflowRight && !overflowLeft) {
            return "left";
          }
          break;
        case "bottom":
          if (overflowBottom && !overflowTop) {
            return "top";
          }
          break;
        case "left":
          if (overflowLeft && !overflowRight) {
            return "right";
          }
          break;
      }
      return placement;
    }
    static findScrollableParents(element) {
      const scrollableParents = [];
      let currentElement = element;
      while (currentElement && currentElement !== document.body) {
        const style = window.getComputedStyle(currentElement);
        if (style.overflow === "auto" || style.overflow === "scroll" || style.overflowX === "auto" || style.overflowX === "scroll" || style.overflowY === "auto" || style.overflowY === "scroll") {
          scrollableParents.push(currentElement);
        }
        currentElement = currentElement.parentElement;
      }
      scrollableParents.push(window);
      return scrollableParents;
    }
  };
  var positioner_default = Positioner;

  // ../deps/cognit/assets/js/ui/core/portal.js
  var _Portal = class {
    static move(element, container = document.body) {
      if (!element)
        return false;
      const originalData = {
        parent: element.parentElement,
        styles: {
          position: element.style.position,
          top: element.style.top,
          left: element.style.left,
          zIndex: element.style.zIndex,
          margin: element.style.margin,
          transform: element.style.transform,
          pointerEvents: element.style.pointerEvents
        },
        inPortal: true
      };
      this.portalRegistry.set(element, originalData);
      container.appendChild(element);
      element.style.position = "absolute";
      element.style.zIndex = "9999";
      return true;
    }
    static restore(element) {
      if (!element)
        return false;
      const originalData = this.portalRegistry.get(element);
      if (!originalData || !originalData.parent) {
        return false;
      }
      try {
        originalData.parent.appendChild(element);
        const styles = originalData.styles;
        element.style.position = styles.position || "";
        element.style.top = styles.top || "";
        element.style.left = styles.left || "";
        element.style.zIndex = styles.zIndex || "";
        element.style.margin = styles.margin || "";
        element.style.transform = styles.transform || "";
        element.style.pointerEvents = styles.pointerEvents || "";
        originalData.inPortal = false;
        return true;
      } catch (error2) {
        console.warn("SaladUI Portal: Failed to restore element", error2);
        return false;
      }
    }
    static isInPortal(element) {
      if (!element)
        return false;
      const data2 = this.portalRegistry.get(element);
      return data2?.inPortal === true;
    }
    static setupScrollPassthrough(element) {
      if (!element)
        return;
      const originalData = this.portalRegistry.get(element);
      if (originalData) {
        originalData.styles.pointerEvents = element.style.pointerEvents;
      }
      element.style.pointerEvents = "none";
      _Portal.updateScrollableContainer(element, "auto");
    }
    static updateScrollableContainer(parentElement, pointerEvent = "") {
      function isScrollable(element) {
        const style = window.getComputedStyle(element);
        const overflowY = style.overflowY;
        const overflowX = style.overflowX;
        const isScrollableY = element.scrollHeight > element.clientHeight;
        const isScrollableX = element.scrollWidth > element.clientWidth;
        return (overflowY === "auto" || overflowY === "scroll" || overflowY === "overlay") && isScrollableY || (overflowX === "auto" || overflowX === "scroll" || overflowX === "overlay") && isScrollableX;
      }
      function traverse(element) {
        if (isScrollable(element)) {
          element.style.pointerEvents = pointerEvent;
          return;
        }
        for (let i = 0; i < element.children.length; i++) {
          traverse(element.children[i]);
        }
      }
      traverse(parentElement);
    }
    static cleanupScrollPassthrough(element) {
      if (!element)
        return;
      const originalData = this.portalRegistry.get(element);
      const originalPointerEvents = originalData?.styles?.pointerEvents || "";
      element.style.pointerEvents = originalPointerEvents;
      _Portal.updateScrollableContainer(element, "");
    }
  };
  var Portal = _Portal;
  __publicField(Portal, "portalRegistry", /* @__PURE__ */ new WeakMap());
  var portal_default = Portal;

  // ../deps/cognit/assets/js/ui/core/scroll-manager.js
  var ScrollManager = class {
    constructor(updateCallback, options = {}) {
      this.updateCallback = updateCallback;
      this.options = {
        useRAF: true,
        ...options
      };
      this.scrollableParents = [];
      this.active = false;
      this.resizeObserver = null;
      this.animationFrameId = null;
      this.handleScroll = this.handleScroll.bind(this);
      this.handleResize = this.handleResize.bind(this);
      this.updatePosition = this.updatePosition.bind(this);
    }
    start(referenceElement, targetElement = null) {
      if (this.active)
        return;
      if (referenceElement) {
        this.scrollableParents = this.findScrollableParents(referenceElement);
        this.scrollableParents.forEach((parent) => {
          parent.addEventListener("scroll", this.handleScroll, { passive: true });
        });
      }
      window.addEventListener("resize", this.handleResize, { passive: true });
      if (targetElement && typeof ResizeObserver !== "undefined") {
        this.resizeObserver = new ResizeObserver(this.updatePosition);
        this.resizeObserver.observe(targetElement);
        if (referenceElement && referenceElement !== targetElement) {
          this.resizeObserver.observe(referenceElement);
        }
      }
      this.active = true;
    }
    stop() {
      if (!this.active)
        return;
      this.scrollableParents.forEach((parent) => {
        parent.removeEventListener("scroll", this.handleScroll);
      });
      window.removeEventListener("resize", this.handleResize);
      if (this.resizeObserver) {
        this.resizeObserver.disconnect();
        this.resizeObserver = null;
      }
      if (this.animationFrameId !== null) {
        cancelAnimationFrame(this.animationFrameId);
        this.animationFrameId = null;
      }
      this.active = false;
      this.scrollableParents = [];
    }
    handleScroll() {
      if (this.options.useRAF) {
        this.throttledUpdate();
      } else {
        this.updatePosition();
      }
    }
    handleResize() {
      if (this.options.useRAF) {
        this.throttledUpdate();
      } else {
        this.updatePosition();
      }
    }
    throttledUpdate() {
      if (this.animationFrameId === null) {
        this.animationFrameId = requestAnimationFrame(() => {
          this.updatePosition();
          this.animationFrameId = null;
        });
      }
    }
    updatePosition() {
      if (this.updateCallback) {
        this.updateCallback();
      }
    }
    findScrollableParents(element) {
      const scrollableParents = [];
      let currentElement = element;
      while (currentElement && currentElement !== document.body) {
        const style = window.getComputedStyle(currentElement);
        if (style.overflow === "auto" || style.overflow === "scroll" || style.overflowX === "auto" || style.overflowX === "scroll" || style.overflowY === "auto" || style.overflowY === "scroll") {
          scrollableParents.push(currentElement);
        }
        currentElement = currentElement.parentElement;
      }
      scrollableParents.push(window);
      return scrollableParents;
    }
    destroy() {
      this.stop();
      this.updateCallback = null;
      this.options = null;
    }
  };
  var scroll_manager_default = ScrollManager;

  // ../deps/cognit/assets/js/ui/core/positioned-element.js
  var PositionedElement = class {
    constructor(element, reference, options = {}) {
      this.element = element;
      this.reference = reference;
      this.options = {
        placement: "bottom",
        alignment: "center",
        sideOffset: 8,
        alignOffset: 0,
        flip: true,
        usePortal: false,
        portalContainer: document.body,
        trapFocus: false,
        focusableSelector: 'a[href], button:not([disabled]), input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])',
        onOutsideClick: null,
        scrollPassThrough: false,
        ...options
      };
      this.active = false;
      this.initializeModules();
    }
    initializeModules() {
      this.focusTrap = new focus_trap_default(this.element, {
        focusableSelector: this.options.focusableSelector
      });
      this.clickOutsideMonitor = this.options.onOutsideClick ? new click_outside_default([this.element, this.reference], this.options.onOutsideClick) : null;
      this.scrollManager = new scroll_manager_default(() => {
        this.update();
      });
      this.handleWheel = this.handleWheel.bind(this);
      this.handleTouchStart = this.handleTouchStart.bind(this);
      this.handleTouchMove = this.handleTouchMove.bind(this);
    }
    activate() {
      if (this.active)
        return this;
      if (this.options.usePortal) {
        this.moveToPortal();
      }
      this.calculateAndApplyPosition();
      if (this.options.trapFocus) {
        this.focusTrap.activate();
      }
      if (this.clickOutsideMonitor) {
        this.clickOutsideMonitor.start();
      }
      this.scrollManager.start(this.reference, this.element);
      if (portal_default.isInPortal(this.element) && this.options.scrollPassThrough) {
        this.setupScrollPassthrough();
      }
      this.element.style.setProperty("--salad-reference-width", this.reference.offsetWidth + "px");
      this.element.style.setProperty("--salad-reference-height", this.reference.offsetHeight + "px");
      this.active = true;
      return this;
    }
    deactivate() {
      if (!this.active)
        return this;
      if (this.options.trapFocus) {
        this.focusTrap.deactivate();
      }
      if (this.clickOutsideMonitor) {
        this.clickOutsideMonitor.stop();
      }
      this.scrollManager.stop();
      if (portal_default.isInPortal(this.element) && this.options.scrollPassThrough) {
        this.cleanupScrollPassthrough();
      }
      if (this.inPortal) {
        this.restoreFromPortal();
      }
      this.active = false;
      return this;
    }
    update() {
      if (this.active) {
        this.calculateAndApplyPosition();
        this.element.style.setProperty("--salad-reference-width", this.reference.offsetWidth + "px");
        this.element.style.setProperty("--salad-reference-height", this.reference.offsetHeight + "px");
      }
      return this;
    }
    moveToPortal() {
      if (portal_default.isInPortal(this.element))
        return;
      const container = this.options.portalContainer || document.body;
      portal_default.move(this.element, container);
    }
    restoreFromPortal() {
      if (!portal_default.isInPortal(this.element))
        return;
      portal_default.restore(this.element);
    }
    calculateAndApplyPosition() {
      const position = positioner_default.calculate(this.element, this.reference, this.options);
      positioner_default.applyPosition(this.element, position.x, position.y);
      this.element.setAttribute("data-placement", position.placement);
      return position;
    }
    setupScrollPassthrough() {
      portal_default.setupScrollPassthrough(this.element, this.options.focusableSelector);
      this.element.addEventListener("wheel", this.handleWheel, {
        passive: false
      });
      this.element.addEventListener("touchstart", this.handleTouchStart, {
        passive: false
      });
      this.element.addEventListener("touchmove", this.handleTouchMove, {
        passive: false
      });
    }
    cleanupScrollPassthrough() {
      if (!this.element)
        return;
      this.element.removeEventListener("wheel", this.handleWheel);
      this.element.removeEventListener("touchstart", this.handleTouchStart);
      this.element.removeEventListener("touchmove", this.handleTouchMove);
      portal_default.cleanupScrollPassthrough(this.element);
    }
    handleWheel(event) {
      event.stopPropagation();
    }
    handleTouchStart(event) {
      if (event.touches.length === 1) {
        this.touchStartY = event.touches[0].clientY;
      }
    }
    handleTouchMove(event) {
      if (!this.touchStartY)
        return;
      const touchY = event.touches[0].clientY;
      const deltaY = this.touchStartY - touchY;
      this.touchStartY = touchY;
      const elementsFromPoint = document.elementsFromPoint(event.touches[0].clientX, event.touches[0].clientY);
      const scrollableElement = elementsFromPoint.find((el) => {
        if (el === this.element || this.element.contains(el))
          return false;
        const style = window.getComputedStyle(el);
        return style.overflowY === "auto" || style.overflowY === "scroll" || el === document.documentElement;
      });
      if (scrollableElement) {
        scrollableElement.scrollTop += deltaY;
        event.preventDefault();
      }
    }
    updateReference(reference) {
      this.reference = reference;
      if (this.clickOutsideMonitor) {
        this.clickOutsideMonitor.updateElements([this.element, this.reference]);
      }
      this.update();
      return this;
    }
    updateOptions(options = {}) {
      this.options = { ...this.options, ...options };
      if (this.focusTrap && options.focusableSelector) {
        this.focusTrap.options = {
          ...this.focusTrap.options,
          focusableSelector: options.focusableSelector
        };
      }
      this.update();
      return this;
    }
    destroy() {
      this.deactivate();
      this.focusTrap.destroy();
      if (this.clickOutsideMonitor) {
        this.clickOutsideMonitor.destroy();
      }
      this.scrollManager.destroy();
      if (portal_default.isInPortal(this.element)) {
        this.element.remove();
      }
      this.element = null;
      this.reference = null;
      this.options = null;
      this.focusTrap = null;
      this.clickOutsideMonitor = null;
      this.scrollManager = null;
      this.touchStartY = null;
    }
  };
  var positioned_element_default = PositionedElement;

  // ../deps/cognit/assets/js/ui/components/select.js
  var SelectItem = class extends component_default {
    constructor(itemElement, parentComponent, options) {
      const { initialState = "normal" } = options || {};
      super(itemElement, { initialState, ignoreItems: false });
      this.parent = parentComponent;
      this.value = itemElement.dataset.value;
      this.disabled = itemElement.dataset.disabled === "true";
      this.label = itemElement.textContent.trim();
      this.setupEvents();
    }
    getComponentConfig() {
      return {
        stateMachine: {
          unchecked: {
            transitions: {
              check: "checked"
            }
          },
          checked: {
            transitions: {
              uncheck: "unchecked"
            }
          }
        },
        events: {
          unchecked: {
            mouseMap: {
              item: {
                click: "handleActivation",
                mouseenter: "handleMouseEnter",
                mouseleave: "handleMouseLeave"
              }
            },
            keyMap: {
              Enter: "handleActivation",
              " ": "handleActivation"
            }
          },
          checked: {
            mouseMap: {
              item: {
                click: "handleActivation",
                mouseenter: "handleMouseEnter",
                mouseleave: "handleMouseLeave"
              }
            },
            keyMap: {
              Enter: "handleActivation",
              " ": "handleActivation"
            }
          }
        },
        hiddenConfig: {
          checked: {
            "item-indicator": false
          },
          unchecked: {
            "item-indicator": true
          }
        },
        ariaConfig: {
          item: {
            all: {
              role: "option"
            },
            checked: {
              selected: "true"
            },
            unchecked: {
              selected: "false"
            }
          }
        }
      };
    }
    handleEvent(eventType) {
      switch (eventType) {
        case "select":
          return this.transition("check");
        case "unselect":
          return this.transition("uncheck");
        case "focus":
          if (!this.disabled) {
            this.el.focus();
          }
          return true;
        case "blur":
          return true;
      }
    }
    handleActivation(event) {
      event.preventDefault();
      event.stopImmediatePropagation();
      if (!this.disabled) {
        this.parent.selectValue(this.value);
      }
    }
    handleMouseEnter() {
      if (!this.disabled) {
        this.parent.handleItemFocus(this);
      }
    }
  };
  var SelectComponent = class extends component_default {
    constructor(el, hookContext) {
      super(el, { hookContext });
      this.trigger = this.getPart("trigger");
      this.valueDisplay = this.getPart("value");
      this.content = this.getPart("content");
      this.disabled = this.el.dataset.disabled === "true";
      this.multiple = this.options.multiple || false;
      this.usePortal = this.options.hasOwnProperty("usePortal") ? this.options.usePortal : false;
      this.portalContainer = this.options.portalContainer || null;
      this.collection = new collection_default({
        type: this.multiple ? "multiple" : "single",
        defaultValue: this.options.defaultValue,
        value: this.multiple ? this.options.value?.map((v) => v?.toString()) : this.options.value?.toString(),
        getItemValue: (item) => item.value,
        isItemDisabled: (item) => item.disabled || this.disabled
      });
      this.config.preventDefaultKeys = [
        "ArrowUp",
        "ArrowDown",
        "Home",
        "End",
        "Enter",
        " ",
        "Escape"
      ];
      this.initializeItems();
      this.initializePlaceholder();
      this.syncHiddenInputs(false);
    }
    getComponentConfig() {
      return {
        stateMachine: {
          closed: {
            enter: "onClosedEnter",
            transitions: {
              open: "open",
              toggle: "open"
            }
          },
          open: {
            enter: "onOpenEnter",
            exit: "onOpenExit",
            transitions: {
              close: "closed",
              toggle: "closed",
              select: "closed"
            }
          }
        },
        events: {
          closed: {
            keyEventTarget: "content",
            keyMap: {
              ArrowDown: "open",
              ArrowUp: "open",
              Enter: "open",
              " ": "open"
            },
            mouseMap: {
              trigger: {
                click: (e) => {
                  e.stopImmediatePropagation();
                  this.transition("open");
                }
              }
            }
          },
          open: {
            keyEventTarget: "content",
            keyMap: {
              Escape: "close",
              ArrowUp: () => this.navigateItem("prev"),
              ArrowDown: () => this.navigateItem("next"),
              Home: () => this.navigateItem("first"),
              End: () => this.navigateItem("last")
            },
            mouseMap: {
              trigger: {
                click: (e) => {
                  e.stopImmediatePropagation();
                  this.transition("close");
                }
              }
            }
          }
        },
        hiddenConfig: {
          closed: {
            content: true
          },
          open: {
            content: false
          }
        },
        ariaConfig: {
          trigger: {
            all: {
              haspopup: "listbox"
            },
            open: {
              expanded: "true"
            },
            closed: {
              expanded: "false"
            }
          },
          content: {
            all: {
              role: "listbox"
            }
          }
        }
      };
    }
    initializeItems() {
      const itemElements = Array.from(this.el.querySelectorAll("[data-part='item']"));
      itemElements.map((element) => {
        const value = element.dataset.value;
        const isSelected = this.collection.isValueSelected(value);
        const initialState = isSelected ? "checked" : "unchecked";
        const item = new SelectItem(element, this, { initialState });
        this.collection.add(item);
      });
      this.updateValueDisplay();
    }
    initializePlaceholder() {
      if (!this.valueDisplay)
        return;
      if (this.collection.getValue(true).length === 0) {
        const placeholder = this.valueDisplay.getAttribute("data-placeholder") || "Select an option";
        this.valueDisplay.replaceChildren(placeholder);
      }
    }
    initializePositionedElement() {
      if (this.content && this.trigger && !this.positionedElement) {
        const side = this.content.getAttribute("data-side") || "bottom";
        let portalContainer = null;
        if (this.portalContainer) {
          portalContainer = document.querySelector(this.portalContainer);
        }
        this.positionedElement = new positioned_element_default(this.content, this.el, {
          placement: side,
          alignment: "start",
          sideOffset: 4,
          flip: true,
          usePortal: this.usePortal,
          portalContainer: portalContainer || document.body,
          trapFocus: false,
          onOutsideClick: () => this.transition("close")
        });
      }
    }
    onClosedEnter() {
      this.syncHiddenInputs();
      this.pushEvent("closed");
    }
    onOpenEnter() {
      this.initializePositionedElement();
      if (this.positionedElement) {
        this.positionedElement.activate();
      }
      this.highlightFirstSelectedOrFirstItem();
      this.pushEvent("opened");
    }
    onOpenExit() {
      if (this.positionedElement) {
        this.positionedElement.deactivate();
      }
    }
    selectValue(value) {
      const collectionItem = this.collection.getItemByValue(value);
      if (!collectionItem)
        return;
      this.collection.select(collectionItem);
      this.updateValueDisplay();
      this.syncHiddenInputs();
      if (!this.multiple) {
        this.transition("select");
      }
      const selectedValue = this.collection.getValue();
      this.pushEvent("value-changed", { value: selectedValue });
    }
    handleItemFocus(item) {
      const collectionItem = this.collection.getItemByInstance(item);
      if (!collectionItem)
        return;
      this.collection.focus(collectionItem);
    }
    updateValueDisplay() {
      if (!this.valueDisplay)
        return;
      const selectedValues = this.collection.getValue(true).filter((v) => v !== "");
      const placeholder = this.valueDisplay.getAttribute("data-placeholder") || "Select an option";
      if (selectedValues.length === 0) {
        this.valueDisplay.replaceChildren(placeholder);
      } else if (this.multiple) {
        if (selectedValues.length === 1) {
          const content = this.collection.getItemByValue(selectedValues[0])?.instance.el.cloneNode(true).querySelector('[data-part="item-text"]') || "";
          this.valueDisplay.replaceChildren(content);
        } else {
          this.valueDisplay.replaceChildren(`${selectedValues.length} items selected`);
        }
      } else {
        const content = this.collection.getItemByValue(selectedValues[0])?.instance.el.cloneNode(true).querySelector('[data-part="item-text"]') || "";
        this.valueDisplay.replaceChildren(content);
      }
    }
    navigateItem(direction) {
      let currentItem = this.collection.focusedItem;
      if (!currentItem) {
        currentItem = this.collection.getValue(true).length > 0 ? this.collection.getItemByValue(this.collection.getValue(true)[0]) : null;
      }
      const targetItem = this.collection.getItem(direction, currentItem);
      if (targetItem) {
        this.collection.focus(targetItem);
      }
    }
    highlightFirstSelectedOrFirstItem() {
      const selectedValue = this.collection.getValue();
      const selectedItem = this.collection.getItemByValue(selectedValue) || this.collection.getItem("first");
      if (selectedItem) {
        this.collection.focus(selectedItem);
      }
    }
    syncHiddenInputs(notifyChanges = true) {
      const values = this.collection.getValue(true);
      const name = this.options.name || "";
      const existingInputs = this.el.querySelectorAll("input[type='hidden']:not([data-input])");
      existingInputs.forEach((input) => input.remove());
      const inputsContainer = this.el.querySelector("[data-inputs-container]");
      if (this.multiple) {
        values.forEach((value) => {
          const input = document.createElement("input");
          input.type = "hidden";
          input.name = name;
          input.value = value;
          inputsContainer.appendChild(input);
        });
      } else if (values.length > 0) {
        const input = document.createElement("input");
        input.type = "hidden";
        input.name = name;
        input.value = values[0];
        inputsContainer.appendChild(input);
      }
      const shouldNotifyChanges = notifyChanges && this.el.dataset.notifyFormChange !== "false";
      if (shouldNotifyChanges) {
        this.el.querySelector("[data-input]").dispatchEvent(new Event("change", { bubbles: true }));
      }
    }
    onDomUpdate() {
      super.onDomUpdate();
      if (this.state === "open" && this.positionedElement) {
        this.positionedElement.update();
      }
      const raw2 = this.options.value;
      if (raw2 !== void 0) {
        const toStr = (v) => v == null || v === "" ? null : v.toString();
        const normalized = raw2 == null || raw2 === "" ? [] : Array.isArray(raw2) ? raw2.map((v) => toStr(v)).filter(Boolean) : [toStr(raw2)].filter(Boolean);
        const current = this.collection.getValue(true);
        if (JSON.stringify(normalized.sort()) !== JSON.stringify(current.sort())) {
          this.collection.setValues(normalized.length ? normalized : null);
        }
      }
      this.reinitializeItems();
      this.updateValueDisplay();
      this.syncHiddenInputs(false);
    }
    reinitializeItems() {
      const selectedValues = this.collection.getValue(true);
      this.collection.each((item) => {
        if (typeof item.destroy === "function") {
          item.destroy();
        }
      });
      this.collection.clear();
      this.disabled = this.el.dataset.disabled === "true";
      const itemElements = Array.from(this.el.querySelectorAll("[data-part='item']"));
      itemElements.forEach((element) => {
        const value = element.dataset.value;
        const isSelected = selectedValues.includes(value);
        const initialState = isSelected ? "checked" : "unchecked";
        const item = new SelectItem(element, this, { initialState });
        this.collection.add(item);
      });
    }
    beforeDestroy() {
      if (this.positionedElement) {
        this.positionedElement.destroy();
        this.positionedElement = null;
      }
      this.collection.each((item) => {
        if (typeof item.destroy === "function") {
          item.destroy();
        }
      });
      this.collection = null;
    }
  };
  ui_default.register("select", SelectComponent);

  // ../deps/cognit/assets/js/ui/components/tabs.js
  var TabsComponent = class extends component_default {
    constructor(el, hookContext) {
      super(el, { hookContext });
      this.list = this.getPart("list");
      this.triggers = this.getAllParts("trigger");
      this.contents = this.getAllParts("content");
      this.config.preventDefaultKeys = [
        "ArrowLeft",
        "ArrowRight",
        "Home",
        "End",
        "Enter",
        " "
      ];
      this.initialize();
    }
    initialize() {
      const persistedValue = this.hook?.__tabsActiveValue;
      this.collection = new collection_default({
        type: "single",
        defaultValue: this.options.defaultValue,
        value: persistedValue || this.options.value,
        getItemValue: (item) => item.getAttribute("data-value"),
        isItemDisabled: (item) => item.getAttribute("data-disabled") === "true"
      });
      this.triggers.forEach((trigger2) => this.collection.add(trigger2));
      this.setupAriaAttributes();
      if (!this.collection.getValue() && this.triggers.length > 0) {
        const firstTrigger = this.collection.getItem("first");
        if (firstTrigger)
          this.collection.select(firstTrigger);
      }
      this.updateActiveTab();
    }
    getComponentConfig() {
      return {
        stateMachine: {
          idle: {
            transitions: { select: "idle" }
          }
        },
        events: {
          idle: {
            keyMap: {
              ArrowLeft: () => this.navigateTab("prev"),
              ArrowRight: () => this.navigateTab("next"),
              Home: () => this.navigateTab("first"),
              End: () => this.navigateTab("last")
            },
            mouseMap: {
              trigger: { click: (event) => this.handleTriggerClick(event) }
            }
          }
        },
        ariaConfig: {
          list: {
            all: { role: "tablist" }
          },
          trigger: {
            all: {
              role: "tab",
              controls: (el) => `${this.el.id}-content-${el.getAttribute("data-value")}`
            }
          },
          content: {
            all: {
              role: "tabpanel",
              tabindex: "0"
            }
          }
        }
      };
    }
    setupAriaAttributes() {
      this.triggers.forEach((trigger2) => {
        const value = trigger2.getAttribute("data-value");
        if (!trigger2.id)
          trigger2.id = `${this.el.id}-trigger-${value}`;
      });
      this.contents.forEach((content) => {
        const value = content.getAttribute("data-value");
        if (!content.id)
          content.id = `${this.el.id}-content-${value}`;
        content.setAttribute("aria-labelledby", `${this.el.id}-trigger-${value}`);
      });
    }
    handleTriggerClick(event) {
      const trigger2 = event.currentTarget;
      if (trigger2.getAttribute("data-disabled") === "true")
        return;
      this.selectTab(trigger2.getAttribute("data-value"));
    }
    selectTab(value) {
      const triggerItem = this.collection.getItemByValue(value);
      if (!triggerItem || this.collection.isValueSelected(value))
        return;
      if (this.options.value == null) {
        this.collection.select(triggerItem);
        this.updateActiveTab();
      }
      triggerItem.instance.focus();
      this.pushEvent("tab-changed", { value, tab: value });
    }
    updateActiveTab() {
      const selectedValue = this.collection.getValue();
      if (selectedValue && this.hook) {
        this.hook.__tabsActiveValue = selectedValue;
      }
      this.triggers.forEach((trigger2) => {
        const value = trigger2.getAttribute("data-value");
        const isActive = value === selectedValue;
        trigger2.setAttribute("data-state", isActive ? "active" : "inactive");
        trigger2.setAttribute("aria-selected", isActive.toString());
        trigger2.tabIndex = isActive ? 0 : -1;
      });
      this.contents.forEach((content) => {
        const value = content.getAttribute("data-value");
        const isActive = value === selectedValue;
        content.setAttribute("data-state", isActive ? "active" : "inactive");
        content.hidden = !isActive;
      });
    }
    navigateTab(direction) {
      const currentItem = this.collection.getItemByValue(this.collection.getValue());
      const nextItem = this.collection.getItem(direction, currentItem);
      if (nextItem)
        this.selectTab(nextItem.value);
    }
    onDomUpdate() {
      this.parseOptions();
      this.initEventMappings();
      if (this.options.value != null && this.options.value !== this.collection.getValue()) {
        this.collection.setValues(this.options.value);
      }
      this.updateActiveTab();
    }
    destroy() {
      this.collection = null;
      super.destroy();
    }
  };
  ui_default.register("tabs", TabsComponent);

  // ../deps/cognit/assets/js/ui/components/radio_group.js
  var RadioGroupComponent = class extends component_default {
    constructor(el, hookContext) {
      super(el, { hookContext, ignoreItems: false });
      this.items = this.getAllParts("item");
      this.config.preventDefaultKeys = [
        "ArrowLeft",
        "ArrowRight",
        "ArrowUp",
        "ArrowDown",
        "Home",
        "End"
      ];
      this.initializeCollection();
    }
    getComponentConfig() {
      return {
        stateMachine: {
          idle: {
            enter: "onIdleEnter",
            transitions: {
              valueChanged: "idle"
            }
          }
        },
        events: {
          idle: {
            keyMap: {
              ArrowLeft: () => this.navigateItem("prev"),
              ArrowRight: () => this.navigateItem("next"),
              ArrowUp: () => this.navigateItem("prev"),
              ArrowDown: () => this.navigateItem("next"),
              Home: () => this.navigateItem("first"),
              End: () => this.navigateItem("last")
            },
            mouseMap: {
              item: {
                click: "handleItemClick"
              }
            }
          }
        },
        ariaConfig: {
          root: {
            all: {
              role: "radiogroup"
            }
          },
          item: {
            all: {
              role: "radio"
            }
          }
        }
      };
    }
    initializeCollection() {
      this.collection = new collection_default({
        type: "single",
        defaultValue: this.options.initialValue,
        getItemValue: (item) => item.getAttribute("data-value"),
        isItemDisabled: (item) => item.getAttribute("data-disabled") === "true"
      });
      this.items.forEach((item) => {
        this.collection.add(item);
        if (!item.id) {
          const value = item.getAttribute("data-value");
          item.id = `${this.el.id}-item-${value}`;
        }
      });
      this.updateItemStates();
    }
    handleItemClick(event) {
      const item = event.currentTarget;
      if (item.getAttribute("data-disabled") === "true")
        return;
      this.selectItem(item);
    }
    selectItem(item) {
      const value = item.getAttribute("data-value");
      const previousValue = this.collection.getValue();
      const collectionItem = this.collection.getItemByInstance(item);
      if (collectionItem && value !== previousValue) {
        this.transition("valueChanged", { value, previousValue });
        this.collection.select(collectionItem);
        this.updateItemStates();
        this.pushEvent("value-changed", {
          value,
          previousValue
        });
        collectionItem.instance?.querySelector("input").dispatchEvent(new Event("change", { bubbles: true }));
      }
    }
    updateItemStates() {
      const selectedValue = this.collection.getValue();
      this.collection.items.forEach((collectionItem) => {
        const item = collectionItem.instance;
        const value = collectionItem.value;
        const isSelected = value === selectedValue;
        const isDisabled = item.getAttribute("data-disabled") === "true";
        item.setAttribute("data-state", isSelected ? "checked" : "unchecked");
        item.setAttribute("aria-checked", isSelected.toString());
        item.setAttribute("tabindex", isSelected ? "0" : "-1");
        const input = item.querySelector('input[type="radio"]');
        if (input) {
          input.checked = isSelected;
          input.disabled = isDisabled;
          if (!input.name && this.options.name) {
            input.name = this.options.name;
          }
        }
      });
    }
    navigateItem(direction) {
      const currentValue = this.collection.getValue();
      const currentItem = this.collection.getItemByValue(currentValue);
      const nextItem = this.collection.getItem(direction, currentItem);
      if (!nextItem)
        return;
      if (typeof nextItem.instance.focus === "function") {
        nextItem.instance.focus();
      } else if (nextItem.instance) {
        nextItem.instance.focus();
      }
      this.selectItem(nextItem.instance);
    }
    onIdleEnter() {
      if (!this.collection.getValue()) {
        const firstItem = this.collection.getItem("first");
        if (firstItem && firstItem.instance) {
          firstItem.instance.setAttribute("tabindex", "0");
        }
      }
    }
    setupComponentEvents() {
      super.setupComponentEvents();
      this.el.addEventListener("focus", (e) => {
        if (e.target === this.el) {
          const selectedValue = this.collection.getValue();
          if (selectedValue) {
            const selectedItem = this.collection.getItemByValue(selectedValue);
            if (selectedItem && selectedItem.instance) {
              selectedItem.instance.focus();
            }
          } else {
            const firstItem = this.collection.getItem("first");
            if (firstItem && firstItem.instance) {
              firstItem.instance.focus();
            }
          }
        }
      });
    }
    onDomUpdate() {
      super.onDomUpdate();
      this.updateItemStates();
    }
    beforeDestroy() {
      this.collection = null;
    }
  };
  ui_default.register("radio-group", RadioGroupComponent);

  // ../deps/cognit/assets/js/ui/components/popover.js
  var PopoverComponent = class extends component_default {
    constructor(el, hookContext) {
      super(el, { hookContext });
      this.trigger = this.getPart("trigger");
      this.positioner = this.getPart("positioner");
      this.content = this.positioner ? this.positioner.querySelector("[data-part='content']") : null;
      this.config.preventDefaultKeys = ["Escape"];
    }
    getComponentConfig() {
      return {
        stateMachine: {
          closed: {
            enter: "onClosedEnter",
            transitions: {
              open: "open",
              toggle: "open"
            }
          },
          open: {
            enter: "onOpenEnter",
            transitions: {
              close: "closed",
              toggle: "closed"
            }
          }
        },
        events: {
          closed: {
            keyMap: {}
          },
          open: {
            keyMap: {
              Escape: "close"
            }
          }
        },
        hiddenConfig: {
          closed: {
            positioner: true
          },
          open: {
            positioner: false
          }
        },
        ariaConfig: {
          trigger: {
            all: {
              haspopup: "dialog"
            },
            open: {
              expanded: "true"
            },
            closed: {
              expanded: "false"
            }
          },
          content: {
            all: {
              role: "dialog"
            }
          }
        }
      };
    }
    initializePositionedElement() {
      if (this.positioner && this.trigger && !this.positionedElement) {
        const placement = this.positioner.getAttribute("data-side") || "bottom";
        const alignment = this.positioner.getAttribute("data-align") || "center";
        const sideOffset = parseInt(this.positioner.getAttribute("data-side-offset") || "8", 10);
        const alignOffset = parseInt(this.positioner.getAttribute("data-align-offset") || "0", 10);
        this.positionedElement = new positioned_element_default(this.positioner, this.trigger, {
          placement,
          alignment,
          sideOffset,
          alignOffset,
          flip: true,
          usePortal: !!this.options.portalContainer,
          portalContainer: document.querySelector(this.options.portalContainer),
          trapFocus: true,
          onOutsideClick: () => this.transition("close")
        });
      }
    }
    onOpenEnter(params = {}) {
      this.initializePositionedElement();
      this.positionedElement?.activate();
      this.pushEvent("opened");
    }
    onClosedEnter() {
      this.positionedElement?.deactivate();
      this.pushEvent("closed");
    }
    onDomUpdate() {
      super.onDomUpdate();
      if (this.state === "open" && this.positionedElement) {
        this.positionedElement.update();
      }
    }
    beforeDestroy() {
      this.positionedElement?.destroy();
      this.positionedElement = null;
    }
  };
  ui_default.register("popover", PopoverComponent);

  // ../deps/cognit/assets/js/ui/components/hover-card.js
  var DEFAULT_POSITION_CONFIG = {
    placement: "top",
    alignment: "center",
    sideOffset: 8,
    alignOffset: 0
  };
  var DEFAULT_TIMING_CONFIG = {
    openDelay: 300,
    closeDelay: 200
  };
  var HoverCardComponent = class extends component_default {
    constructor(el, hookContext) {
      super(el, { hookContext });
      this.trigger = this.getPart("trigger");
      this.content = this.getPart("content");
      this.config.openDelay = this.options.openDelay || DEFAULT_TIMING_CONFIG.openDelay;
      this.config.closeDelay = this.options.closeDelay || DEFAULT_TIMING_CONFIG.closeDelay;
      this.openTimer = null;
      this.closeTimer = null;
    }
    getComponentConfig() {
      return {
        stateMachine: {
          closed: {
            enter: "onClosedEnter",
            transitions: {
              open: "open"
            }
          },
          open: {
            enter: "onOpenEnter",
            exit: "onOpenExit",
            transitions: {
              close: "closed"
            }
          }
        },
        events: {
          closed: {
            mouseMap: {
              trigger: {
                mouseenter: "delayOpen",
                focus: "delayOpen"
              }
            }
          },
          open: {
            mouseMap: {
              trigger: {
                mouseleave: "delayClose",
                blur: "delayClose"
              },
              content: {
                mouseenter: "clearTimers",
                mouseleave: "delayClose"
              }
            }
          }
        },
        hiddenConfig: {
          closed: {
            content: true
          },
          open: {
            content: false
          }
        },
        ariaConfig: {
          trigger: {
            all: {
              haspopup: "dialog"
            },
            open: {
              expanded: "true"
            },
            closed: {
              expanded: "false"
            }
          },
          content: {
            all: {
              role: "dialog"
            }
          }
        }
      };
    }
    delayOpen() {
      this.clearTimers();
      this.openTimer = setTimeout(() => {
        this.transition("open");
      }, this.config.openDelay);
    }
    delayClose() {
      this.clearTimers();
      this.closeTimer = setTimeout(() => {
        this.transition("close");
      }, this.config.closeDelay);
    }
    clearTimers() {
      if (this.openTimer) {
        clearTimeout(this.openTimer);
        this.openTimer = null;
      }
      if (this.closeTimer) {
        clearTimeout(this.closeTimer);
        this.closeTimer = null;
      }
    }
    initializePositionedElement() {
      if (this.positionedElement)
        return;
      if (!this.trigger || !this.content)
        return;
      const positionConfig = {
        placement: this.content.getAttribute("data-side") || DEFAULT_POSITION_CONFIG.placement,
        alignment: this.content.getAttribute("data-align") || DEFAULT_POSITION_CONFIG.alignment,
        sideOffset: parseInt(this.content.getAttribute("data-side-offset"), 10) || DEFAULT_POSITION_CONFIG.sideOffset,
        alignOffset: parseInt(this.content.getAttribute("data-align-offset"), 10) || DEFAULT_POSITION_CONFIG.alignOffset,
        flip: true,
        usePortal: false,
        trapFocus: false
      };
      this.positionedElement = new positioned_element_default(this.content, this.trigger, positionConfig);
    }
    onOpenEnter() {
      this.initializePositionedElement();
      if (this.positionedElement) {
        this.positionedElement.activate();
      }
      this.pushEvent("opened");
    }
    onOpenExit() {
      if (this.positionedElement) {
        this.positionedElement.deactivate();
      }
    }
    onClosedEnter() {
      this.pushEvent("closed");
    }
    onDomUpdate() {
      super.onDomUpdate();
      if (this.state === "open" && this.positionedElement) {
        this.positionedElement.update();
      }
    }
    beforeDestroy() {
      this.clearTimers();
      if (this.positionedElement) {
        this.positionedElement.destroy();
        this.positionedElement = null;
      }
    }
  };
  ui_default.register("hover-card", HoverCardComponent);

  // ../deps/cognit/assets/js/ui/components/collapsible.js
  var CollapsibleComponent = class extends component_default {
    constructor(el, hookContext) {
      super(el, { hookContext });
      this.trigger = this.getPart("trigger");
      this.content = this.getPart("content");
      this.config.preventDefaultKeys = ["Enter", " "];
    }
    getComponentConfig() {
      return {
        stateMachine: {
          closed: {
            enter: "onClosedEnter",
            transitions: {
              toggle: "open",
              open: "open"
            }
          },
          open: {
            enter: "onOpenEnter",
            transitions: {
              toggle: "closed",
              close: "closed"
            }
          }
        },
        events: {
          closed: {
            keyMap: {
              Enter: "toggle",
              " ": "toggle"
            }
          },
          open: {
            keyMap: {
              Enter: "toggle",
              " ": "toggle"
            }
          }
        },
        hiddenConfig: {
          closed: {
            content: true
          },
          open: {
            content: false
          }
        },
        ariaConfig: {
          trigger: {
            all: {
              controls: () => this.getPartId("content")
            },
            open: {
              expanded: "true"
            },
            closed: {
              expanded: "false"
            }
          },
          content: {
            all: {
              labelledby: () => this.getPartId("trigger"),
              role: "region"
            }
          }
        }
      };
    }
    onOpenEnter() {
      this.pushEvent("opened");
    }
    onClosedEnter() {
      this.pushEvent("closed");
    }
  };
  ui_default.register("collapsible", CollapsibleComponent);

  // ../deps/cognit/assets/js/ui/components/tooltip.js
  var DEFAULT_POSITION_CONFIG2 = {
    placement: "top",
    alignment: "center",
    sideOffset: 8,
    alignOffset: 0
  };
  var DEFAULT_TIMING_CONFIG2 = {
    openDelay: 150,
    closeDelay: 100
  };
  var TooltipComponent = class extends component_default {
    constructor(el, hookContext) {
      super(el, { hookContext });
      this.trigger = this.getPart("trigger") || this.el.querySelector(":first-child");
      this.content = this.getPart("content");
      this.config.openDelay = this.options.openDelay ?? DEFAULT_TIMING_CONFIG2.openDelay;
      this.config.closeDelay = this.options.closeDelay ?? DEFAULT_TIMING_CONFIG2.closeDelay;
      this.openTimer = null;
      this.closeTimer = null;
    }
    getComponentConfig() {
      return {
        stateMachine: {
          closed: {
            enter: "onClosedEnter",
            transitions: {
              open: "open"
            }
          },
          open: {
            enter: "onOpenEnter",
            exit: "onOpenExit",
            transitions: {
              close: "closed"
            }
          }
        },
        events: {
          closed: {
            mouseMap: {
              trigger: {
                mouseenter: "delayOpen",
                focus: "delayOpen",
                mouseleave: "clearTimers",
                blur: "clearTimers"
              }
            }
          },
          open: {
            mouseMap: {
              trigger: {
                mouseleave: "delayClose",
                blur: "delayClose"
              },
              content: {
                mouseenter: "clearTimers",
                mouseleave: "delayClose"
              }
            }
          }
        },
        hiddenConfig: {
          closed: {
            content: true
          },
          open: {
            content: false
          }
        },
        ariaConfig: {
          trigger: {
            all: {
              describedby: () => this.getPartId("content")
            }
          },
          content: {
            all: {
              role: "tooltip"
            }
          }
        }
      };
    }
    delayOpen() {
      this.clearTimers();
      this.openTimer = setTimeout(() => {
        this.transition("open");
      }, this.config.openDelay);
    }
    delayClose() {
      this.clearTimers();
      this.closeTimer = setTimeout(() => {
        this.transition("close");
      }, this.config.closeDelay);
    }
    clearTimers() {
      if (this.openTimer) {
        clearTimeout(this.openTimer);
        this.openTimer = null;
      }
      if (this.closeTimer) {
        clearTimeout(this.closeTimer);
        this.closeTimer = null;
      }
    }
    initializePositionedElement() {
      if (this.positionedElement)
        return;
      if (!this.trigger || !this.content)
        return;
      const positionConfig = {
        placement: this.content.getAttribute("data-side") || DEFAULT_POSITION_CONFIG2.placement,
        alignment: this.content.getAttribute("data-align") || DEFAULT_POSITION_CONFIG2.alignment,
        sideOffset: parseInt(this.content.getAttribute("data-side-offset"), 10) || DEFAULT_POSITION_CONFIG2.sideOffset,
        alignOffset: parseInt(this.content.getAttribute("data-align-offset"), 10) || DEFAULT_POSITION_CONFIG2.alignOffset,
        flip: true,
        usePortal: false,
        trapFocus: false
      };
      this.positionedElement = new positioned_element_default(this.content, this.trigger, positionConfig);
    }
    onOpenEnter() {
      this.initializePositionedElement();
      if (this.positionedElement) {
        this.positionedElement.activate();
      }
      this.pushEvent("opened");
    }
    onOpenExit() {
      if (this.positionedElement) {
        this.positionedElement.destroy();
        this.positionedElement = null;
      }
    }
    onClosedEnter() {
      this.pushEvent("closed");
    }
    onDomUpdate() {
      super.onDomUpdate();
      if (this.state === "open") {
        if (this.positionedElement) {
          this.positionedElement.update();
        } else {
          this.initializePositionedElement();
          this.positionedElement?.activate();
        }
      }
    }
    beforeDestroy() {
      this.clearTimers();
      if (this.positionedElement) {
        this.positionedElement.destroy();
        this.positionedElement = null;
      }
    }
  };
  ui_default.register("tooltip", TooltipComponent);

  // ../deps/cognit/assets/js/ui/components/accordion.js
  var AccordionItem = class extends component_default {
    constructor(itemElement, parentComponent, options) {
      const { initialState = "closed" } = options || {};
      super(itemElement, { initialState, ignoreItems: false });
      this.parent = parentComponent;
      this.value = itemElement.dataset.value;
      this.disabled = itemElement.dataset.disabled === "true";
      this.trigger = itemElement.querySelector("[data-part='item-trigger']");
      this.content = itemElement.querySelector("[data-part='item-content']");
      this.initialize();
      this.setupEvents();
    }
    getComponentConfig() {
      return {
        stateMachine: {
          closed: {
            transitions: {
              open: "open"
            }
          },
          open: {
            transitions: {
              close: "closed"
            }
          }
        },
        events: {
          closed: {
            mouseMap: {
              "item-trigger": {
                click: "handleTriggerActivation"
              }
            },
            keyMap: {
              Enter: "handleTriggerActivation",
              " ": "handleTriggerActivation"
            }
          },
          open: {
            mouseMap: {
              "item-trigger": {
                click: "handleTriggerActivation"
              }
            },
            keyMap: {
              Enter: "handleTriggerActivation",
              " ": "handleTriggerActivation"
            }
          }
        },
        hiddenConfig: {
          closed: {
            "item-content": true
          },
          open: {
            "item-content": false
          }
        },
        ariaConfig: {
          "item-trigger": {
            all: {
              controls: () => this.content?.id
            },
            open: {
              expanded: "true"
            },
            closed: {
              expanded: "false"
            }
          },
          "item-content": {
            all: {
              labelledby: () => this.trigger?.id
            }
          }
        }
      };
    }
    initialize() {
      if (this.disabled) {
        this.trigger.setAttribute("tabindex", "-1");
      } else {
        this.trigger.setAttribute("tabindex", "0");
      }
    }
    handleEvent(eventType) {
      switch (eventType) {
        case "select":
          return this.transition("open");
        case "unselect":
          return this.transition("close");
        case "focus":
          if (this.trigger && !this.disabled) {
            this.trigger.focus();
          }
          return true;
        case "blur":
          return true;
      }
    }
    handleTriggerActivation(event) {
      event.preventDefault();
      if (!this.disabled && !this.parent.disabled) {
        this.parent.toggleItem(this);
      }
    }
  };
  var AccordionComponent = class extends component_default {
    constructor(el, hookContext) {
      super(el, { hookContext });
      this.type = this.options.type || "single";
      this.disabled = this.options.disabled || false;
      this.collection = new collection_default({
        type: this.type,
        defaultValue: this.options.defaultValue,
        value: this.options.value,
        getItemValue: (item) => item.value,
        isItemDisabled: (item) => item.disabled || this.disabled
      });
      this.config.preventDefaultKeys = [
        "ArrowUp",
        "ArrowDown",
        "Home",
        "End",
        "Enter",
        " "
      ];
      this.initializeItems();
    }
    getComponentConfig() {
      return {
        stateMachine: {
          idle: {
            enter: () => {
            },
            exit: () => {
            },
            transitions: {}
          }
        },
        events: {
          idle: {
            keyMap: {
              ArrowUp: () => this.navigateItem("prev"),
              ArrowDown: () => this.navigateItem("next"),
              Home: () => this.navigateItem("first"),
              End: () => this.navigateItem("last")
            }
          }
        }
      };
    }
    initializeItems() {
      const itemElements = Array.from(this.el.querySelectorAll("[data-part='item']"));
      this.items = itemElements.map((element) => {
        const itemValue = element.dataset.value;
        element.id = `${this.el.id}-item-${itemValue}`;
        const isOpen = this.collection.getValue(true).includes(itemValue);
        const item = new AccordionItem(element, this, {
          initialState: isOpen ? "open" : "closed"
        });
        this.collection.add(item);
        return item;
      });
    }
    toggleItem(item) {
      const collectionItem = this.collection.getItemByInstance(item);
      if (!collectionItem)
        return;
      this.collection.select(collectionItem);
      const value = this.collection.getValue();
      this.pushEvent("value-changed", { value });
    }
    navigateItem(direction) {
      const currentFocus = document.activeElement;
      const currentItemElement = currentFocus?.closest("[data-part='item']");
      let currentItem = null;
      if (currentItemElement) {
        currentItem = this.items.find((item) => item.el === currentItemElement);
      }
      let referenceCollectionItem = null;
      if (currentItem) {
        referenceCollectionItem = this.collection.getItemByInstance(currentItem);
      }
      const targetItem = this.collection.getItem(direction, referenceCollectionItem);
      if (targetItem) {
        this.collection.focus(targetItem);
      }
    }
  };
  ui_default.register("accordion", AccordionComponent);

  // ../deps/cognit/assets/js/ui/components/slider.js
  var SliderComponent = class extends component_default {
    constructor(el, hookContext) {
      super(el, { hookContext });
      this.track = this.getPart("track");
      this.range = this.getPart("range");
      this.thumb = this.getPart("thumb");
      this.parseValues();
      this.isDragging = false;
      this.setupDragHandling();
      this.updatePosition();
    }
    parseValues() {
      this.min = parseFloat(this.options.min || 0);
      this.max = parseFloat(this.options.max || 100);
      this.step = parseFloat(this.options.step || 1);
      this.disabled = !!this.options.disabled;
      const dataValue = this.el.dataset.value;
      const defaultValue = this.options.defaultValue;
      this.value = parseFloat(dataValue !== void 0 && dataValue !== null ? dataValue : defaultValue !== void 0 ? defaultValue : this.min);
      this.value = Math.max(this.min, Math.min(this.max, this.value));
    }
    getComponentConfig() {
      return {
        stateMachine: {
          idle: {
            enter: "onIdleEnter",
            transitions: {
              drag: "dragging"
            }
          },
          dragging: {
            enter: "onDraggingEnter",
            exit: "onDraggingExit",
            transitions: {
              end: "idle"
            }
          }
        },
        events: {
          idle: {
            keyMap: {
              ArrowLeft: () => this.decrementValue(),
              ArrowRight: () => this.incrementValue(),
              ArrowDown: () => this.decrementValue(),
              ArrowUp: () => this.incrementValue(),
              Home: () => this.setValueAndUpdate(this.min),
              End: () => this.setValueAndUpdate(this.max)
            }
          },
          dragging: {}
        },
        ariaConfig: {
          root: {
            all: {
              role: "slider",
              valuemin: () => this.min?.toString(),
              valuemax: () => this.max?.toString(),
              valuenow: () => this.value?.toString(),
              valuetext: () => this.value?.toString(),
              orientation: "horizontal",
              disabled: () => this.disabled ? "true" : null
            }
          }
        }
      };
    }
    setupDragHandling() {
      this.onPointerMove = this.onPointerMove.bind(this);
      this.onPointerUp = this.onPointerUp.bind(this);
      this.onPointerDown = this.onPointerDown.bind(this);
      this.el.addEventListener("mousedown", this.onPointerDown);
      this.el.addEventListener("touchstart", this.onPointerDown, {
        passive: false
      });
    }
    onIdleEnter() {
      this.el.setAttribute("tabindex", "0");
    }
    onDraggingEnter() {
      document.addEventListener("mousemove", this.onPointerMove);
      document.addEventListener("touchmove", this.onPointerMove, {
        passive: false
      });
      document.addEventListener("mouseup", this.onPointerUp);
      document.addEventListener("touchend", this.onPointerUp);
    }
    onDraggingExit() {
      document.removeEventListener("mousemove", this.onPointerMove);
      document.removeEventListener("touchmove", this.onPointerMove);
      document.removeEventListener("mouseup", this.onPointerUp);
      document.removeEventListener("touchend", this.onPointerUp);
    }
    onPointerDown(event) {
      if (this.disabled)
        return;
      event.preventDefault();
      this.transition("drag");
      this.updateValueFromPointer(event);
    }
    onPointerMove(event) {
      event.preventDefault();
      this.updateValueFromPointer(event);
    }
    onPointerUp() {
      this.transition("end");
      this.pushEvent("value-changed", { value: this.value });
    }
    updateValueFromPointer(event) {
      const clientX = event.touches ? event.touches[0].clientX : event.clientX;
      const trackRect = this.track.getBoundingClientRect();
      let percentage = Math.max(0, Math.min(1, (clientX - trackRect.left) / trackRect.width));
      const rawValue = this.min + percentage * (this.max - this.min);
      const steppedValue = Math.round(rawValue / this.step) * this.step;
      this.setValueAndUpdate(steppedValue);
    }
    incrementValue() {
      this.setValueAndUpdate(Math.min(this.max, this.value + this.step));
      this.pushEvent("value-changed", { value: this.value });
    }
    decrementValue() {
      this.setValueAndUpdate(Math.max(this.min, this.value - this.step));
      this.pushEvent("value-changed", { value: this.value });
    }
    setValueAndUpdate(newValue) {
      this.value = Math.max(this.min, Math.min(this.max, newValue));
      this.updatePosition();
      this.el.setAttribute("aria-valuenow", this.value.toString());
      this.el.setAttribute("aria-valuetext", this.value.toString());
    }
    updatePosition() {
      const percentage = (this.value - this.min) / (this.max - this.min) * 100;
      this.range.style.width = `${percentage}%`;
      const trackRect = this.track.getBoundingClientRect();
      const thumbRect = this.thumb.getBoundingClientRect();
      const thumbHalfWidthPercentage = thumbRect.width / 2 / trackRect.width * 100;
      const thumbPercentage = Math.max(thumbHalfWidthPercentage, Math.min(100 - thumbHalfWidthPercentage, percentage));
      this.thumb.style.left = `${thumbPercentage}%`;
      this.thumb.style.transform = "translateX(-50%)";
    }
    handleCommand(command, params) {
      if (command === "setValue") {
        this.setValueAndUpdate(parseFloat(params.value));
        return true;
      }
      return super.handleCommand(command, params);
    }
    beforeDestroy() {
      document.removeEventListener("mousemove", this.onPointerMove);
      document.removeEventListener("touchmove", this.onPointerMove);
      document.removeEventListener("mouseup", this.onPointerUp);
      document.removeEventListener("touchend", this.onPointerUp);
      this.el.removeEventListener("mousedown", this.onPointerDown);
      this.el.removeEventListener("touchstart", this.onPointerDown);
    }
  };
  ui_default.register("slider", SliderComponent);

  // ../deps/cognit/assets/js/ui/components/switch.js
  var SwitchComponent = class extends component_default {
    constructor(el, hookContext) {
      super(el, { hookContext });
      this.initialState = this.el.getAttribute("data-state");
    }
    getComponentConfig() {
      return {
        stateMachine: {
          checked: {
            enter: "onCheckedEnter",
            transitions: {
              toggle: "unchecked"
            }
          },
          unchecked: {
            enter: "onUncheckedEnter",
            transitions: {
              toggle: "checked"
            }
          }
        },
        events: {
          checked: {
            mouseMap: {
              root: {
                click: "toggleSwitch"
              }
            },
            keyMap: {
              " ": "toggleSwitch",
              Enter: "toggleSwitch"
            }
          },
          unchecked: {
            mouseMap: {
              root: {
                click: "toggleSwitch"
              }
            },
            keyMap: {
              " ": "toggleSwitch",
              Enter: "toggleSwitch"
            }
          }
        },
        ariaConfig: {
          root: {
            all: {
              role: "switch"
            },
            checked: {
              checked: "true"
            },
            unchecked: {
              checked: "false"
            }
          }
        }
      };
    }
    toggleSwitch(e) {
      if (this.disabled)
        return;
      this.transition("toggle");
      e.stopImmediatePropagation();
    }
    setupComponentEvents() {
      this.el.setAttribute("tabindex", this.el.getAttribute("disabled") === "true" ? "-1" : "0");
      this.config.preventDefaultKeys = [" ", "Enter"];
    }
    onCheckedEnter(e) {
      const checkbox = this.el.querySelector('input[type="checkbox"]');
      if (checkbox) {
        checkbox.checked = true;
        checkbox.dispatchEvent(new Event("change", { bubbles: true }));
      }
      this.pushEvent("checked-changed", { value: true });
    }
    onUncheckedEnter(e) {
      const checkbox = this.el.querySelector('input[type="checkbox"]');
      if (checkbox) {
        checkbox.checked = false;
        checkbox.dispatchEvent(new Event("change", { bubbles: true }));
      }
      this.pushEvent("checked-changed", { value: false });
    }
  };
  ui_default.register("switch", SwitchComponent);

  // ../deps/cognit/assets/js/ui/components/menu.js
  var MenuItemBase = class extends component_default {
    constructor(itemElement, parentComponent, options) {
      super(itemElement, {
        ...options,
        initialState: "idle",
        ignoreItems: false
      });
      this.parent = parentComponent;
      this.hook = this.parent.hook;
      this.value = itemElement.value || itemElement.getAttribute("data-value") || itemElement.textContent.trim();
      this.disabled = itemElement.getAttribute("data-disabled") !== null;
      this.config.preventDefaultKeys = [" ", "Enter"];
      this.setupEvents();
    }
    getComponentConfig() {
      return {
        stateMachine: {
          idle: {}
        },
        events: {
          idle: {
            mouseMap: {
              item: {
                click: "handleActivation",
                mouseenter: "handleMouseEnter"
              }
            },
            keyMap: {
              " ": "handleActivation",
              Enter: "handleActivation"
            }
          }
        },
        ariaConfig: {
          item: {
            all: {
              role: "menuitem",
              disabled: () => this.disabled ? "true" : null
            }
          }
        }
      };
    }
    handleEvent(eventType) {
      switch (eventType) {
        case "focus":
          if (!this.disabled) {
            this.transition("focus");
            this.el.focus();
          }
          return true;
        case "blur":
          this.transition("blur");
          return true;
      }
    }
    handleActivation(event) {
      if (this.disabled)
        return;
      this.pushEvent("item-selected", {
        value: this.value
      }, this.parent.el);
      this.parent.selectItem(this);
    }
    handleMouseEnter() {
      if (!this.disabled) {
        this.parent.handleItemFocus(this);
      }
    }
  };
  var MenuItem = class extends MenuItemBase {
    constructor(itemElement, parentComponent, options) {
      super(itemElement, parentComponent, options);
    }
  };
  var MenuCheckboxItem = class extends MenuItemBase {
    constructor(itemElement, parentComponent, options) {
      super(itemElement, parentComponent, options);
    }
    getComponentConfig() {
      return {
        stateMachine: {
          checked: {
            transitions: {
              toggle: "unchecked"
            }
          },
          unchecked: {
            transitions: {
              toggle: "checked"
            }
          }
        },
        events: {
          checked: {
            mouseMap: {
              "checkbox-item": {
                click: "handleActivation",
                mouseleave: "handleMouseLeave"
              }
            },
            keyMap: {
              " ": "handleActivation",
              Enter: "handleActivation"
            }
          },
          unchecked: {
            mouseMap: {
              "checkbox-item": {
                click: "handleActivation",
                mouseleave: "handleMouseLeave"
              }
            },
            keyMap: {
              " ": "handleActivation",
              Enter: "handleActivation"
            }
          }
        },
        hiddenConfig: {
          checked: {
            "item-indicator": false
          },
          unchecked: {
            "item-indicator": true
          }
        },
        ariaConfig: {
          item: {
            all: {
              role: "menuitemcheckbox",
              disabled: () => this.disabled ? "true" : null,
              checked: () => this.state == "checked" ? "true" : "false"
            }
          }
        }
      };
    }
    handleActivation(event) {
      super.handleActivation(event);
      if (event) {
        event.preventDefault();
        event.stopPropagation();
        event.stopImmediatePropagation();
      }
      if (this.disabled)
        return;
      this.transition("toggle");
      this.pushEvent("checked-changed", {
        value: this.value,
        checked: this.state == "checked"
      }, this.parent.el);
    }
  };
  var Menu = class extends component_default {
    constructor(el, { hookContext, onItemSelect }) {
      super(el, { hookContext });
      this.onItemSelect = onItemSelect || (() => {
      });
      this.menuItems = [];
      this.config.preventDefaultKeys = ["ArrowDown", "ArrowUp", "Home", "End"];
      this.initializeItems();
      this.initializeCollection();
      this.setupEvents();
    }
    getComponentConfig() {
      return {
        stateMachine: {
          idle: {
            transitions: {}
          }
        },
        events: {
          _all: {
            keyMap: {
              ArrowDown: () => this.navigateItem("next"),
              ArrowUp: () => this.navigateItem("prev"),
              Home: () => this.navigateItem("first"),
              End: () => this.navigateItem("last")
            }
          }
        },
        ariaConfig: {}
      };
    }
    initializeItems() {
      const allItemElements = Array.from(this.el.querySelectorAll("[data-part='item'], [data-part='checkbox-item']"));
      this.menuItems = allItemElements.map((element) => {
        const itemType = element.getAttribute("data-part");
        switch (itemType) {
          case "checkbox-item":
            return new MenuCheckboxItem(element, this, {
              initialState: "normal"
            });
          default:
            return new MenuItem(element, this, {
              initialState: "normal"
            });
        }
      });
    }
    initializeCollection() {
      this.collection = new collection_default({
        type: "single",
        getItemValue: (item) => item.value,
        isItemDisabled: (item) => item.disabled
      });
      this.menuItems.forEach((item) => {
        this.collection.add(item);
      });
    }
    activate() {
      const firstItem = this.collection.getItem("first");
      if (firstItem) {
        this.collection.focus(firstItem);
      }
    }
    selectItem(item) {
      if (item.disabled)
        return;
      this.onItemSelect(item);
    }
    handleItemFocus(item) {
      const collectionItem = this.collection.getItemByInstance(item);
      if (!collectionItem)
        return;
      this.collection.focus(collectionItem);
    }
    navigateItem(direction) {
      let currentItem = this.collection.focusedItem;
      const targetItem = this.collection.getItem(direction, currentItem);
      if (targetItem) {
        this.collection.focus(targetItem);
      }
    }
    beforeDestroy() {
      if (this.menuItems) {
        this.menuItems.forEach((item) => {
          if (typeof item.destroy === "function") {
            item.destroy();
          }
        });
        this.menuItems = null;
      }
      this.collection = null;
    }
  };
  var menu_default = Menu;

  // ../deps/cognit/assets/js/ui/components/dropdown_menu.js
  var DropdownMenuComponent = class extends component_default {
    constructor(el, hookContext) {
      super(el, { hookContext });
      this.trigger = this.getPart("trigger");
      this.positioner = this.getPart("positioner");
      this.content = this.positioner.querySelector("[data-part='content']");
      this.menu = new menu_default(this.content, {
        hookContext,
        onItemSelect: this.onItemSelect.bind(this)
      });
      this.config.preventDefaultKeys = ["Escape", "ArrowDown", " ", "Enter"];
    }
    getComponentConfig() {
      return {
        stateMachine: {
          closed: {
            enter: "onClosedEnter",
            transitions: {
              open: "open",
              toggle: "open"
            }
          },
          open: {
            enter: "onOpenEnter",
            transitions: {
              close: "closed",
              toggle: "closed"
            }
          }
        },
        events: {
          closed: {
            keyMap: {
              ArrowDown: "open",
              " ": "open",
              Enter: "open"
            },
            mouseMap: {
              trigger: {
                click: (_e) => {
                  this.transition("open");
                }
              }
            }
          },
          open: {
            keyMap: {
              Escape: "close"
            }
          }
        },
        hiddenConfig: {
          closed: {
            positioner: true
          },
          open: {
            positioner: false
          }
        },
        ariaConfig: {
          trigger: {
            all: {
              haspopup: "menu",
              controls: () => this.content ? this.content.id || `${this.el.id}-content` : null
            },
            open: {
              expanded: "true"
            },
            closed: {
              expanded: "false"
            }
          },
          content: {
            all: {
              role: "menu"
            }
          }
        }
      };
    }
    initializePositionedElement() {
      if (this.positioner && this.trigger && !this.positionedElement) {
        const side = this.positioner.getAttribute("data-side") || "bottom";
        const align = this.positioner.getAttribute("data-align") || "start";
        const sideOffset = parseInt(this.positioner.getAttribute("data-side-offset") || "4", 10);
        const alignOffset = parseInt(this.positioner.getAttribute("data-align-offset") || "0", 10);
        const usePortal = this.options.usePortal === true;
        let portalContainer = null;
        if (this.options.portalContainer) {
          portalContainer = document.querySelector(this.options.portalContainer);
        }
        this.positionedElement = new positioned_element_default(this.positioner, this.trigger, {
          placement: side,
          alignment: align,
          sideOffset,
          alignOffset,
          flip: true,
          usePortal,
          portalContainer: portalContainer || document.body,
          trapFocus: false,
          onOutsideClick: () => this.transition("close")
        });
      }
    }
    onOpenEnter() {
      this.previousFocusEl = document.activeElement;
      this.initializePositionedElement();
      this.positionedElement?.activate();
      this.menu.activate();
      this.pushEvent("opened");
    }
    onClosedEnter() {
      this.positionedElement?.deactivate();
      this.pushEvent("closed");
      this.previousFocusEl?.focus();
      this.previousFocusEl = null;
    }
    onItemSelect(_item) {
      this.transition("close");
    }
    onDomUpdate() {
      super.onDomUpdate();
      if (this.state === "open" && this.positionedElement) {
        this.positionedElement.update();
      }
    }
    beforeDestroy() {
      if (this.positionedElement) {
        this.positionedElement.destroy();
        this.positionedElement = null;
      }
      if (this.menu) {
        this.menu.destroy();
        this.menu = null;
      }
    }
  };
  ui_default.register("dropdown-menu", DropdownMenuComponent);

  // ../deps/cognit/assets/js/copy_button.js
  window.addEventListener("cognit:copy", (event) => {
    let text;
    if (event.detail?.text) {
      text = event.detail.text;
    } else if (event.detail?.target) {
      const targetElement = document.querySelector(event.detail.target);
      if (!targetElement) {
        console.error(`Copy button: target element not found: ${event.detail.target}`);
        return;
      }
      text = targetElement.value || targetElement.textContent;
    } else {
      text = event.target.value || event.target.textContent;
    }
    if (!text) {
      console.warn("Copy button: no text to copy");
      return;
    }
    if (!navigator.clipboard) {
      console.error("Copy button: Clipboard API not available. Requires HTTPS or localhost.");
      fallbackCopy(text);
      return;
    }
    navigator.clipboard.writeText(text).then(() => {
      showCopyFeedback(event.target);
    }).catch((err) => {
      console.error("Failed to copy:", err);
      fallbackCopy(text);
    });
  });
  function showCopyFeedback(element) {
    const btn = element.closest("button[data-copy-feedback-target]") || element;
    const tooltip = btn.closest('[data-component="tooltip"]');
    if (!tooltip) {
      console.warn("Copy feedback tooltip not found");
      return;
    }
    tooltip.dispatchEvent(new CustomEvent("salad_ui:command", {
      detail: {
        command: "open",
        params: {}
      },
      bubbles: false
    }));
    setTimeout(() => {
      tooltip.dispatchEvent(new CustomEvent("salad_ui:command", {
        detail: {
          command: "close",
          params: {}
        },
        bubbles: false
      }));
    }, 2e3);
  }
  function fallbackCopy(text) {
    const textarea = document.createElement("textarea");
    textarea.value = text;
    textarea.style.position = "fixed";
    textarea.style.opacity = "0";
    document.body.appendChild(textarea);
    textarea.select();
    try {
      const successful = document.execCommand("copy");
      if (successful) {
        console.log("Fallback copy successful");
      } else {
        console.error("Fallback copy failed");
      }
    } catch (err) {
      console.error("Fallback copy error:", err);
    } finally {
      document.body.removeChild(textarea);
    }
  }

  // ../deps/cognit/assets/js/hooks/flash_message.js
  var FlashMessage = {
    timer: null,
    remove() {
      this.el.remove();
      clearTimeout(this.timer);
      this.liveSocket.execJS(this.el, this.el.getAttribute("phx-remove"));
    },
    mounted() {
      const type = this.el.dataset.type;
      if (type !== "error") {
        this.timer = setTimeout(() => {
          this.remove();
        }, 5e3);
      }
    }
  };

  // ../deps/cognit/assets/js/hooks/pagination.js
  var Pagination = {
    mounted() {
      this.submitting = false;
      this.el.addEventListener("pagination:navigate", (e) => {
        const { page, page_size } = e.detail;
        this.handleChange(page, page_size);
      });
      this.el.addEventListener("change", (e) => {
        const form = e.target.closest("form");
        if (!form)
          return;
        const formData = new FormData(form);
        const page = parseInt(formData.get("page")) || 1;
        const pageSize = parseInt([...formData.getAll("page_size")].pop());
        if (Number.isFinite(pageSize)) {
          this.handleChange(page, pageSize);
        }
      });
    },
    handleChange(page, pageSize) {
      const event = this.el.dataset.onChange;
      if (event) {
        const target = this.el.dataset.target;
        this.pushEventTo(target || this.el, event, {
          page,
          page_size: pageSize
        });
      } else {
        this.patchUrl(page, pageSize);
      }
    },
    patchUrl(page, pageSize) {
      if (this.submitting)
        return;
      this.submitting = true;
      const url = new URL(window.location.href);
      if (Number.isFinite(page))
        url.searchParams.set("page", page);
      if (Number.isFinite(pageSize))
        url.searchParams.set("page_size", pageSize);
      this.liveSocket.js().patch(url.toString());
      setTimeout(() => {
        this.submitting = false;
      }, 100);
    }
  };

  // ../deps/cognit/assets/js/hooks/sidebar.js
  var Sidebar = {
    mounted() {
      const sidebarRoot = this.el;
      const observer2 = new MutationObserver((mutations) => {
        mutations.forEach((mutation) => {
          if (mutation.type === "attributes" && mutation.attributeName === "data-state") {
            const state = sidebarRoot.getAttribute("data-state");
            if (state) {
              this.saveSidebarState(state);
              this.handleTransition();
            }
          }
        });
      });
      observer2.observe(sidebarRoot, {
        attributes: true,
        attributeFilter: ["data-state"]
      });
      this.observer = observer2;
    },
    handleTransition() {
      const sidebarRoot = this.el;
      sidebarRoot.classList.add("is-transitioning");
      clearTimeout(this.transitionTimer);
      this.transitionTimer = setTimeout(() => {
        sidebarRoot.classList.remove("is-transitioning");
      }, 200);
    },
    saveSidebarState(state) {
      const EXPIRY_TIME_IN_DAYS = 365;
      const expiryDate = new Date();
      expiryDate.setTime(expiryDate.getTime() + EXPIRY_TIME_IN_DAYS * 24 * 60 * 60 * 1e3);
      const expires = "expires=" + expiryDate.toUTCString();
      document.cookie = `sidebar_state=${state};${expires};path=/`;
    },
    destroyed() {
      if (this.observer) {
        this.observer.disconnect();
      }
      clearTimeout(this.transitionTimer);
    }
  };

  // ../deps/cognit/assets/js/hooks/sidebar_menu.js
  var SidebarMenu = {
    mounted() {
      this.updateActiveItems();
    },
    updateActiveItems() {
      const currentPath = window.location.pathname;
      const allButtons = this.el.querySelectorAll('[data-sidebar="menu-button"], [data-sidebar="menu-sub-button"]');
      allButtons.forEach((button) => {
        const href = button.getAttribute("href");
        if (href && (currentPath === href || currentPath.startsWith(href + "/"))) {
          button.setAttribute("data-active", "true");
        } else {
          button.setAttribute("data-active", "false");
        }
      });
      this.openActiveCollapsibles();
    },
    openActiveCollapsibles() {
      const activeSubButtons = this.el.querySelectorAll('[data-sidebar="menu-sub-button"][data-active="true"]');
      activeSubButtons.forEach((button) => {
        const collapsible = button.closest('[data-component="collapsible"]');
        if (collapsible) {
          collapsible.setAttribute("data-state", "open");
          const parentButton = collapsible.querySelector('[data-sidebar="menu-button"]');
          if (parentButton) {
            parentButton.setAttribute("data-active", "true");
          }
        }
      });
    }
  };

  // ../deps/cognit/assets/js/connect_params.js
  function getCookie(name) {
    const cookies = document.cookie.split("; ");
    const cookie = cookies.find((c) => c.startsWith(`${name}=`));
    return cookie ? cookie.split("=")[1] : null;
  }
  function getCognitParams() {
    return {
      sidebar_state: getCookie("sidebar_state") || "expanded"
    };
  }

  // js/app.js
  var socketPath = document.querySelector("html").getAttribute("phx-socket") || "/live";
  var csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");
  window.Alpine = module_default;
  module_default.start();
  var Hooks = {};
  var LocaleSelect = {
    mounted() {
      this.el.addEventListener("set-locale", (event) => {
        this.setLocale(event.detail.locale);
      });
    },
    setLocale(locale) {
      const expiryDate = new Date();
      expiryDate.setTime(expiryDate.getTime() + 365 * 24 * 60 * 60 * 1e3);
      document.cookie = `app_locale=${locale};expires=${expiryDate.toUTCString()};path=/`;
      const url = new URL(window.location.href);
      url.searchParams.set("locale", locale);
      window.location.assign(url.toString());
    }
  };
  Hooks.FlashMessage = FlashMessage;
  Hooks.ExLingoColorPicker = ExLingoColorPicker;
  Hooks.ExLingoGlossaryCapture = ExLingoGlossaryCapture;
  Hooks.ExLingoInlineEdit = ExLingoInlineEdit;
  Hooks.ExLingoListContext = ExLingoListContext;
  Hooks.ExLingoSaveIndicator = ExLingoSaveIndicator;
  Hooks.LocaleSelect = LocaleSelect;
  Hooks.Pagination = Pagination;
  Hooks.Sidebar = Sidebar;
  Hooks.SidebarMenu = SidebarMenu;
  Hooks.SaladUI = SaladUIHook;
  Hooks.Select = Select;
  Hooks.Toggle = Toggle;
  var liveSocket = new LiveView.LiveSocket(socketPath, Phoenix.Socket, {
    hooks: Hooks,
    dom: {
      onBeforeElUpdated(from, to) {
        if (from._x_dataStack) {
          window.Alpine.clone(from, to);
        }
      }
    },
    params: () => {
      return {
        ...getCognitParams(),
        _csrf_token: csrfToken
      };
    }
  });
  var socket = liveSocket.socket;
  var originalOnConnError = socket.onConnError;
  var fallbackToLongPoll = true;
  socket.onOpen(() => {
    fallbackToLongPoll = false;
  });
  socket.onConnError = (...args) => {
    if (fallbackToLongPoll) {
      fallbackToLongPoll = false;
      socket.disconnect(null, 3e3);
      socket.transport = Phoenix.LongPoll;
      socket.connect();
    } else {
      originalOnConnError.apply(socket, args);
    }
  };
  liveSocket.connect();
  window.liveSocket = liveSocket;
})();
