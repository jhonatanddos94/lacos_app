'use strict';

const SEED_START_A = '2030-06-03T13:00:00.000Z';
const SEED_START_B = '2030-06-03T15:00:00.000Z';

const TENANTS = Object.freeze({
  A: Object.freeze({
    label: 'A',
    username: 'teste_a',
    salonName: 'Salon A',
    responsibleName: 'Teste A',
    professionalName: 'Profissional A',
    role: 'Proprietária',
    specialties: 'Cabelo',
    clientName: 'Cliente A',
    phone: '67999990001',
    serviceName: 'Corte A',
    price: 100,
    startAt: SEED_START_A,
  }),
  B: Object.freeze({
    label: 'B',
    username: 'teste_b',
    salonName: 'Salon B',
    responsibleName: 'Teste B',
    professionalName: 'Profissional B',
    role: 'Proprietária',
    specialties: 'Cabelo',
    clientName: 'Cliente B',
    phone: '67999990002',
    serviceName: 'Corte B',
    price: 200,
    startAt: SEED_START_B,
  }),
});

function pointer(className, objectId) {
  return { __type: 'Pointer', className, objectId };
}

function userPointer(objectId) {
  return pointer('_User', objectId);
}

function parseDate(iso) {
  return { __type: 'Date', iso };
}

function addMinutes(iso, minutes) {
  return new Date(new Date(iso).getTime() + minutes * 60 * 1000).toISOString();
}

function firstResult(body) {
  if (!body || !Array.isArray(body.results) || body.results.length === 0) {
    return null;
  }
  return body.results[0];
}

function createParseClient({ env, http }) {
  async function request({ method, path, query, body }) {
    const url = new URL(`${env.serverURL}${path}`);
    if (query) {
      Object.entries(query).forEach(([key, value]) => {
        url.searchParams.set(
          key,
          typeof value === 'string' ? value : JSON.stringify(value),
        );
      });
    }

    const response = await http({
      method,
      url: url.toString(),
      headers: {
        'X-Parse-Application-Id': env.applicationId,
        'X-Parse-Master-Key': env.masterKey,
        'Content-Type': 'application/json',
      },
      body,
    });

    return response;
  }

  async function findOne(className, where) {
    const response = await request({
      method: 'GET',
      path: `/classes/${className}`,
      query: { where, limit: 1 },
    });
    if (response.status >= 400) {
      const error = new Error(
        `Find ${className} failed status=${response.status} code=${response.body && response.body.code}`,
      );
      error.code = 'SEED_QUERY';
      throw error;
    }
    return firstResult(response.body);
  }

  async function create(className, fields) {
    const response = await request({
      method: 'POST',
      path: `/classes/${className}`,
      body: fields,
    });
    if (response.status >= 400 || !response.body || !response.body.objectId) {
      const error = new Error(
        `Create ${className} failed status=${response.status} code=${response.body && response.body.code}`,
      );
      error.code = 'SEED_CREATE';
      throw error;
    }
    return { objectId: response.body.objectId, created: true };
  }

  async function update(className, objectId, fields) {
    const response = await request({
      method: 'PUT',
      path: `/classes/${className}/${objectId}`,
      body: fields,
    });
    if (response.status >= 400) {
      const error = new Error(
        `Update ${className} failed status=${response.status} code=${response.body && response.body.code}`,
      );
      error.code = 'SEED_UPDATE';
      throw error;
    }
    return { objectId, created: false };
  }

  async function findOrCreate(className, where, fields) {
    const existing = await findOne(className, where);
    if (existing && existing.objectId) {
      return { objectId: existing.objectId, created: false };
    }
    return create(className, fields);
  }

  return {
    request,
    findOne,
    create,
    update,
    findOrCreate,
  };
}

async function resolveSeedUsers(client) {
  const userA = await client.findOne('_User', { username: TENANTS.A.username });
  const userB = await client.findOne('_User', { username: TENANTS.B.username });

  if (!userA || !userA.objectId) {
    const error = new Error(
      `Staging user "${TENANTS.A.username}" was not found. Create it before seeding.`,
    );
    error.code = 'SEED_USER_MISSING';
    throw error;
  }

  if (!userB || !userB.objectId) {
    const error = new Error(
      `Staging user "${TENANTS.B.username}" was not found. Create it before seeding.`,
    );
    error.code = 'SEED_USER_MISSING';
    throw error;
  }

  if (userA.objectId === userB.objectId) {
    const error = new Error(
      'teste_a and teste_b resolved to the same _User. Aborting.',
    );
    error.code = 'SEED_USER_COLLISION';
    throw error;
  }

  return {
    A: { objectId: userA.objectId, username: TENANTS.A.username },
    B: { objectId: userB.objectId, username: TENANTS.B.username },
  };
}

async function upsertWorkingHours(client, { salonId, professionalId }) {
  const ids = [];
  let createdCount = 0;

  for (let weekday = 1; weekday <= 7; weekday += 1) {
    const where = {
      salon: pointer('Salon', salonId),
      professional: pointer('Professional', professionalId),
      weekday,
    };
    const fields = {
      weekday,
      isWorking: true,
      startMinutes: 540,
      endMinutes: 1080,
      salon: pointer('Salon', salonId),
      professional: pointer('Professional', professionalId),
    };

    const existing = await client.findOne('ProfessionalWorkingHours', where);
    if (existing && existing.objectId) {
      await client.update('ProfessionalWorkingHours', existing.objectId, fields);
      ids.push(existing.objectId);
    } else {
      const created = await client.create('ProfessionalWorkingHours', fields);
      ids.push(created.objectId);
      createdCount += 1;
    }
  }

  return { ids, createdCount, count: ids.length };
}

async function seedTenant(client, spec, userId) {
  const salon = await client.findOrCreate(
    'Salon',
    { owner: userPointer(userId), name: spec.salonName },
    {
      name: spec.salonName,
      responsibleName: spec.responsibleName,
      isActive: true,
      owner: userPointer(userId),
    },
  );

  const professional = await client.findOrCreate(
    'Professional',
    { salon: pointer('Salon', salon.objectId), name: spec.professionalName },
    {
      name: spec.professionalName,
      role: spec.role,
      specialties: spec.specialties,
      isActive: true,
      salon: pointer('Salon', salon.objectId),
    },
  );

  const clientRecord = await client.findOrCreate(
    'Client',
    { salon: pointer('Salon', salon.objectId), phone: spec.phone },
    {
      name: spec.clientName,
      phone: spec.phone,
      isActive: true,
      isFavorite: false,
      salon: pointer('Salon', salon.objectId),
      owner: userPointer(userId),
    },
  );

  const service = await client.findOrCreate(
    'Service',
    { salon: pointer('Salon', salon.objectId), name: spec.serviceName },
    {
      name: spec.serviceName,
      durationMinutes: 60,
      price: spec.price,
      isActive: true,
      salon: pointer('Salon', salon.objectId),
      owner: userPointer(userId),
    },
  );

  const endAt = addMinutes(spec.startAt, 60);
  const appointment = await client.findOrCreate(
    'Appointment',
    {
      salon: pointer('Salon', salon.objectId),
      client: pointer('Client', clientRecord.objectId),
      startAt: parseDate(spec.startAt),
    },
    {
      client: pointer('Client', clientRecord.objectId),
      professional: pointer('Professional', professional.objectId),
      salon: pointer('Salon', salon.objectId),
      owner: userPointer(userId),
      startAt: parseDate(spec.startAt),
      endAt: parseDate(endAt),
      status: 'pending',
      isActive: true,
    },
  );

  const hours = await upsertWorkingHours(client, {
    salonId: salon.objectId,
    professionalId: professional.objectId,
  });

  return {
    userId,
    salonId: salon.objectId,
    professionalId: professional.objectId,
    clientId: clientRecord.objectId,
    serviceId: service.objectId,
    appointmentId: appointment.objectId,
    workingHoursIds: hours.ids,
    workingHoursCount: hours.count,
    created: {
      salon: salon.created,
      professional: professional.created,
      client: clientRecord.created,
      service: service.created,
      appointment: appointment.created,
      workingHours: hours.createdCount,
    },
  };
}

async function seedCrossTenants({ env, http }) {
  if (!env || !env.masterKey || !env.applicationId || !env.serverURL) {
    const error = new Error('Staging seed env is incomplete.');
    error.code = 'STAGING_GATE';
    throw error;
  }

  const client = createParseClient({ env, http });
  const users = await resolveSeedUsers(client);
  const tenantA = await seedTenant(client, TENANTS.A, users.A.objectId);
  const tenantB = await seedTenant(client, TENANTS.B, users.B.objectId);

  return {
    A: tenantA,
    B: tenantB,
    users,
  };
}

function buildManifest(result) {
  return {
    generatedAt: new Date().toISOString(),
    A: {
      username: TENANTS.A.username,
      userId: result.A.userId,
      salonId: result.A.salonId,
      professionalId: result.A.professionalId,
      clientId: result.A.clientId,
      serviceId: result.A.serviceId,
      appointmentId: result.A.appointmentId,
      workingHoursIds: result.A.workingHoursIds,
    },
    B: {
      username: TENANTS.B.username,
      userId: result.B.userId,
      salonId: result.B.salonId,
      professionalId: result.B.professionalId,
      clientId: result.B.clientId,
      serviceId: result.B.serviceId,
      appointmentId: result.B.appointmentId,
      workingHoursIds: result.B.workingHoursIds,
    },
  };
}

module.exports = {
  TENANTS,
  SEED_START_A,
  SEED_START_B,
  pointer,
  userPointer,
  parseDate,
  addMinutes,
  createParseClient,
  resolveSeedUsers,
  upsertWorkingHours,
  seedTenant,
  seedCrossTenants,
  buildManifest,
};
