const ExpertHelp = require('../model/experthelp');
const NotificationHelper = require('../utils/notificationHelper');
const { uploadBase64Image, deleteImage } = require('../utils/cloudinaryUpload');

const createExpert = async (req, res) => {
    try {
        const { userid, associatename, address, longitude, latitude, description, contactinfo, clinic_image } = req.body;

        if (!associatename) {
            return res.status(400).json({ message: 'Associate name is required' });
        }

        let clinicImagePath = null;
        if (clinic_image && typeof clinic_image === 'string' && clinic_image.length > 0) {
            try {
                clinicImagePath = await uploadBase64Image(clinic_image, 'experts', 'expert_clinic');
            } catch (err) {
                console.error('Error saving clinic image:', err);
            }
        }

        const newExpert = await ExpertHelp.createExpert({
            userid,
            associatename,
            address,
            longitude,
            latitude,
            description,
            contactinfo,
            clinic_image: clinicImagePath
        });
        if (newExpert) {
            await NotificationHelper.notifyNewClinic(associatename, newExpert.exid);
            res.status(201).json({
                message: 'Expert record created successfully',
                data: newExpert
            });
    } 
        }catch (error) {
        console.error('Controller error in createExpert:', error);
        res.status(500).json({ message: 'Internal server error', error: error.message });
    }
};

const getAllExperts = async (req, res) => {
    try {
        const experts = await ExpertHelp.getAllExperts();
        res.status(200).json(experts);
    } catch (error) {
        console.error('Controller error in getAllExperts:', error);
        res.status(500).json({ message: 'Internal server error', error: error.message });
    }
};

const getExpertById = async (req, res) => {
    try {
        const { id } = req.params;
        const expert = await ExpertHelp.getExpertById(id);

        if (!expert) {
            return res.status(404).json({ message: 'Expert record not found' });
        }

        res.status(200).json(expert);
    } catch (error) {
        console.error('Controller error in getExpertById:', error);
        res.status(500).json({ message: 'Internal server error', error: error.message });
    }
};

const updateExpert = async (req, res) => {
    try {
        const { id } = req.params;
        const { associatename, address, longitude, latitude, description, contactinfo, clinic_image } = req.body;

        const current = await ExpertHelp.getExpertById(id);
        if (!current) {
            return res.status(404).json({ message: 'Expert record not found' });
        }

        let clinicImagePath = clinic_image;
        if (clinic_image === undefined) {
            clinicImagePath = current.clinic_image;
        } else if (clinic_image === null || clinic_image === '') {
            if (current.clinic_image) {
                try {
                    await deleteImage(current.clinic_image);
                } catch (err) {
                    console.error('Error deleting clinic image file:', err);
                }
            }
            clinicImagePath = null;
        } else if (typeof clinic_image === 'string' && clinic_image.length > 0) {
            try {
                clinicImagePath = await uploadBase64Image(clinic_image, 'experts', 'expert_clinic');
                if (current.clinic_image) {
                    await deleteImage(current.clinic_image);
                }
            } catch (err) {
                console.error('Error saving clinic image:', err);
                clinicImagePath = current.clinic_image;
            }
        }

        const updatedExpert = await ExpertHelp.updateExpert(id, {
            associatename,
            address,
            longitude,
            latitude,
            description,
            contactinfo,
            clinic_image: clinicImagePath
        });

        if (!updatedExpert) {
            return res.status(404).json({ message: 'Expert record not found or update failed' });
        }

        res.status(200).json({
            message: 'Expert record updated successfully',
            data: updatedExpert
        });
    } catch (error) {
        console.error('Controller error in updateExpert:', error);
        res.status(500).json({ message: 'Internal server error', error: error.message });
    }
};

const deleteExpert = async (req, res) => {
    try {
        const { id } = req.params;
        const expert = await ExpertHelp.getExpertById(id);
        if (expert && expert.clinic_image) {
            await deleteImage(expert.clinic_image);
        }
        const deletedExpert = await ExpertHelp.deleteExpert(id);

        if (!deletedExpert) {
            return res.status(404).json({ message: 'Expert record not found' });
        }

        res.status(200).json({
            message: 'Expert record deleted successfully',
            data: deletedExpert
        });
    } catch (error) {
        console.error('Controller error in deleteExpert:', error);
        res.status(500).json({ message: 'Internal server error', error: error.message });
    }
};

module.exports = {
    createExpert,
    getAllExperts,
    getExpertById,
    updateExpert,
    deleteExpert
};
