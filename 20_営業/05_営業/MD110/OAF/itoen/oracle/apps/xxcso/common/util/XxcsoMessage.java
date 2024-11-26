/*============================================================================
* �t�@�C���� : XxcsoMessage
* �T�v����   : ���b�Z�[�W�쐬�N���X
* �o�[�W���� : 1.2
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-05 1.0  SCS����_    �V�K�쐬
* 2008-11-11 1.0  SCS����_    createMessage���C��
* 2008-11-20 1.0  SCS����_    �R�����g��@return���L�q
* 2008-11-20 1.0  SCS����_    �x���I�����b�Z�[�W�쐬������ǉ�
* 2008-11-27 1.0  SCS�������l  SQL�G���[���b�Z�[�W�쐬������ǉ�
* 2008-12-02 1.0  SCS�������l  CSV�쐬���G���[���b�Z�[�W�쐬������ǉ�
* 2008-12-05 1.0  SCS����_    ������n�G���[���b�Z�[�W�쐬������ǉ�
* 2008-12-05 1.0  SCS����_    �ُ�n�G���[���b�Z�[�W�쐬������ǉ�
* 2008-12-07 1.0  SCS����_    �X�V�f�[�^�Ȃ��x�����b�Z�[�W�쐬������ǉ�
* 2008-12-10 1.0  SCS����_    �ő�o�^�����G���[���b�Z�[�W�쐬������ǉ�
* 2008-12-11 1.0  SCS����_    ����I�����b�Z�[�W�쐬������ǉ�
* 2022-04-05 1.1  SCSK�񑺗I�� [E_�{�ғ�_18060]���̋@�ڋq�ʗ��v�Ǘ�
* 2024-09-04 1.2  SCSK�Ԓn�w   [E_�{�ғ�_20174]���̋@�ڋq�x���Ǘ����̉��C
*============================================================================
*/
package itoen.oracle.apps.xxcso.common.util;

import java.sql.SQLException;
import java.io.UnsupportedEncodingException;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.common.MessageToken;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;

/*******************************************************************************
 * �A�h�I���F���b�Z�[�W���쐬����N���X�ł��B
 * @author  SCS����_
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoMessage 
{
  /*****************************************************************************
   * ����I�����̃��b�Z�[�W���쐬���܂��i�g�[�N�����j�B
   * @param messageName ���b�Z�[�W��
   * @return OAException ���탁�b�Z�[�W
   *****************************************************************************
   */
  public static OAException createConfirmMessage(
    String messageName
  )
  {
    return
      createConfirmMessage(
        messageName,
        null,
        null
      );
  }

  /*****************************************************************************
   * ����I�����̃��b�Z�[�W���쐬���܂��i�g�[�N���P�j�B
   * @param messageName ���b�Z�[�W��
   * @param tokenName   �g�[�N����
   * @param tokenValue  �g�[�N���l
   * @return OAException ���탁�b�Z�[�W
   *****************************************************************************
   */
  public static OAException createConfirmMessage(
    String messageName,
    String tokenName,
    String tokenValue
  )
  {
    return
      createConfirmMessage(
        messageName,
        tokenName,
        tokenValue,
        null,
        null
      );
  }

  /*****************************************************************************
   * ����I�����̃��b�Z�[�W���쐬���܂��i�g�[�N���Q�j�B
   * @param messageName ���b�Z�[�W��
   * @param tokenName1  �g�[�N���P��
   * @param tokenValue1 �g�[�N���P�l
   * @param tokenName2  �g�[�N���Q��
   * @param tokenValue2 �g�[�N���Q�l
   * @return OAException ���탁�b�Z�[�W
   *****************************************************************************
   */
  public static OAException createConfirmMessage(
    String messageName,
    String tokenName1,
    String tokenValue1,
    String tokenName2,
    String tokenValue2
  )
  {
    return
      createConfirmMessage(
        messageName,
        tokenName1,
        tokenValue1,
        tokenName2,
        tokenValue2,
        null,
        null
      );    
  }

  /*****************************************************************************
   * ����I�����̃��b�Z�[�W���쐬���܂��i�g�[�N���R�j�B
   * @param messageName ���b�Z�[�W��
   * @param tokenName1  �g�[�N���P��
   * @param tokenValue1 �g�[�N���P�l
   * @param tokenName2  �g�[�N���Q��
   * @param tokenValue2 �g�[�N���Q�l
   * @param tokenName3  �g�[�N���R��
   * @param tokenValue3 �g�[�N���R�l
   * @return OAException ���탁�b�Z�[�W
   *****************************************************************************
   */
  public static OAException createConfirmMessage(
    String messageName,
    String tokenName1,
    String tokenValue1,
    String tokenName2,
    String tokenValue2,
    String tokenName3,
    String tokenValue3
  )
  {
    return
      createMessage(
        "XXCSO",
        OAException.CONFIRMATION,
        messageName,
        tokenName1,
        tokenValue1,
        tokenName2,
        tokenValue2,
        tokenName3,
        tokenValue3
      );
  }

  /*****************************************************************************
   * �x���I�����̃��b�Z�[�W���쐬���܂��i�g�[�N�����j�B
   * @param messageName ���b�Z�[�W��
   * @return OAException �x�����b�Z�[�W
   *****************************************************************************
   */
  public static OAException createWarningMessage(
    String messageName
  )
  {
    return
      createWarningMessage(
        messageName,
        null,
        null
      );        
  }

  /*****************************************************************************
   * �x���I�����̃��b�Z�[�W���쐬���܂��i�g�[�N���P�j�B
   * @param messageName ���b�Z�[�W��
   * @param tokenName   �g�[�N����
   * @param tokenValue  �g�[�N���l
   * @return OAException �x�����b�Z�[�W
   *****************************************************************************
   */
  public static OAException createWarningMessage(
    String messageName,
    String tokenName,
    String tokenValue
  )
  {
    return
      createWarningMessage(
        messageName,
        tokenName,
        tokenValue,
        null,
        null
      );        
  }

  /*****************************************************************************
   * �x���I�����̃��b�Z�[�W���쐬���܂��i�g�[�N���Q�j�B
   * @param messageName ���b�Z�[�W��
   * @param tokenName1  �g�[�N���P��
   * @param tokenValue1 �g�[�N���P�l
   * @param tokenName2  �g�[�N���Q��
   * @param tokenValue2 �g�[�N���Q�l
   * @return OAException �x�����b�Z�[�W
   *****************************************************************************
   */
  public static OAException createWarningMessage(
    String messageName,
    String tokenName1,
    String tokenValue1,
    String tokenName2,
    String tokenValue2
  )
  {
    return
      createWarningMessage(
        messageName,
        tokenName1,
        tokenValue1,
        tokenName2,
        tokenValue2,
        null,
        null
      );    
  }

  /*****************************************************************************
   * �x���I�����̃��b�Z�[�W���쐬���܂��i�g�[�N���R�j�B
   * @param messageName ���b�Z�[�W��
   * @param tokenName1  �g�[�N���P��
   * @param tokenValue1 �g�[�N���P�l
   * @param tokenName2  �g�[�N���Q��
   * @param tokenValue2 �g�[�N���Q�l
   * @param tokenName3  �g�[�N���R��
   * @param tokenValue3 �g�[�N���R�l
   * @return OAException �x�����b�Z�[�W
   *****************************************************************************
   */
  public static OAException createWarningMessage(
    String messageName,
    String tokenName1,
    String tokenValue1,
    String tokenName2,
    String tokenValue2,
    String tokenName3,
    String tokenValue3
  )
  {
    return
      createMessage(
        "XXCSO",
        OAException.WARNING,
        messageName,
        tokenName1,
        tokenValue1,
        tokenName2,
        tokenValue2,
        tokenName3,
        tokenValue3
      );
  }

// Ver.1.1 Add Start
  /*****************************************************************************
   * �x���I�����̃��b�Z�[�W���쐬���܂��i�g�[�N���R�j�B
   * @param messageName ���b�Z�[�W��
   * @param tokenName1  �g�[�N���P��
   * @param tokenValue1 �g�[�N���P�l
   * @param tokenName2  �g�[�N���Q��
   * @param tokenValue2 �g�[�N���Q�l
   * @param tokenName3  �g�[�N���R��
   * @param tokenValue3 �g�[�N���R�l
   * @param tokenName4  �g�[�N���S��
   * @param tokenValue4 �g�[�N���S�l
   * @param tokenName5  �g�[�N���T��
   * @param tokenValue5 �g�[�N���T�l
   * @param tokenName6  �g�[�N���U��
   * @param tokenValue6 �g�[�N���U�l
   * @return OAException �x�����b�Z�[�W
   *****************************************************************************
   */
  public static OAException createWarningMessage(
    String messageName,
    String tokenName1,
    String tokenValue1,
    String tokenName2,
    String tokenValue2,
    String tokenName3,
    String tokenValue3,
    String tokenName4,
    String tokenValue4,
    String tokenName5,
    String tokenValue5,
    String tokenName6,
    String tokenValue6
  )
  {
    return
      createMessage(
        "XXCSO",
        OAException.WARNING,
        messageName,
        tokenName1,
        tokenValue1,
        tokenName2,
        tokenValue2,
        tokenName3,
        tokenValue3,
        tokenName4,
        tokenValue4,
        tokenName5,
        tokenValue5,
        tokenName6,
        tokenValue6
      );
  }
// Ver.1.1 Add End
// Ver.1.2 Add Start
  /*****************************************************************************
   * �x���I�����̃��b�Z�[�W���쐬���܂��i�g�[�N���V�j�B
   * @param messageName ���b�Z�[�W��
   * @param tokenName1  �g�[�N���P��
   * @param tokenValue1 �g�[�N���P�l
   * @param tokenName2  �g�[�N���Q��
   * @param tokenValue2 �g�[�N���Q�l
   * @param tokenName3  �g�[�N���R��
   * @param tokenValue3 �g�[�N���R�l
   * @param tokenName4  �g�[�N���S��
   * @param tokenValue4 �g�[�N���S�l
   * @param tokenName5  �g�[�N���T��
   * @param tokenValue5 �g�[�N���T�l
   * @param tokenName6  �g�[�N���U��
   * @param tokenValue6 �g�[�N���U�l
   * @param tokenName7  �g�[�N���V��
   * @param tokenValue7 �g�[�N���V�l
   * @return OAException �x�����b�Z�[�W
   *****************************************************************************
   */
  public static OAException createWarningMessage(
    String messageName,
    String tokenName1,
    String tokenValue1,
    String tokenName2,
    String tokenValue2,
    String tokenName3,
    String tokenValue3,
    String tokenName4,
    String tokenValue4,
    String tokenName5,
    String tokenValue5,
    String tokenName6,
    String tokenValue6,
    String tokenName7,
    String tokenValue7
  )
  {
    return
      createMessage(
        "XXCSO",
        OAException.WARNING,
        messageName,
        tokenName1,
        tokenValue1,
        tokenName2,
        tokenValue2,
        tokenName3,
        tokenValue3,
        tokenName4,
        tokenValue4,
        tokenName5,
        tokenValue5,
        tokenName6,
        tokenValue6,
        tokenName7,
        tokenValue7
      );
  }
// Ver.1.2 Add End
  /*****************************************************************************
   * �G���[�I�����̃��b�Z�[�W���쐬���܂��i�g�[�N�����j�B
   * @param messageName ���b�Z�[�W��
   * @return OAException �G���[���b�Z�[�W
   *****************************************************************************
   */
  public static OAException createErrorMessage(
    String messageName
  )
  {
    return
      createErrorMessage(
        messageName,
        null,
        null
      );        
  }

  /*****************************************************************************
   * �G���[�I�����̃��b�Z�[�W���쐬���܂��i�g�[�N���P�j�B
   * @param messageName ���b�Z�[�W��
   * @param tokenName   �g�[�N����
   * @param tokenValue  �g�[�N���l
   * @return OAException �G���[���b�Z�[�W
   *****************************************************************************
   */
  public static OAException createErrorMessage(
    String messageName,
    String tokenName,
    String tokenValue
  )
  {
    return
      createErrorMessage(
        messageName,
        tokenName,
        tokenValue,
        null,
        null
      );        
  }

  /*****************************************************************************
   * �G���[�I�����̃��b�Z�[�W���쐬���܂��i�g�[�N���Q�j�B
   * @param messageName ���b�Z�[�W��
   * @param tokenName1  �g�[�N���P��
   * @param tokenValue1 �g�[�N���P�l
   * @param tokenName2  �g�[�N���Q��
   * @param tokenValue2 �g�[�N���Q�l
   * @return OAException �G���[���b�Z�[�W
   *****************************************************************************
   */
  public static OAException createErrorMessage(
    String messageName,
    String tokenName1,
    String tokenValue1,
    String tokenName2,
    String tokenValue2
  )
  {
    return
      createErrorMessage(
        messageName,
        tokenName1,
        tokenValue1,
        tokenName2,
        tokenValue2,
        null,
        null
      );    
  }

  /*****************************************************************************
   * �G���[�I�����̃��b�Z�[�W���쐬���܂��i�g�[�N���R�j�B
   * @param messageName ���b�Z�[�W��
   * @param tokenName1  �g�[�N���P��
   * @param tokenValue1 �g�[�N���P�l
   * @param tokenName2  �g�[�N���Q��
   * @param tokenValue2 �g�[�N���Q�l
   * @param tokenName3  �g�[�N���R��
   * @param tokenValue3 �g�[�N���R�l
   * @return OAException �G���[���b�Z�[�W
   *****************************************************************************
   */
  public static OAException createErrorMessage(
    String messageName,
    String tokenName1,
    String tokenValue1,
    String tokenName2,
    String tokenValue2,
    String tokenName3,
    String tokenValue3
  )
  {
    return
      createMessage(
        "XXCSO",
        OAException.ERROR,
        messageName,
        tokenName1,
        tokenValue1,
        tokenName2,
        tokenValue2,
        tokenName3,
        tokenValue3
      );
  }

  /*****************************************************************************
   * �C���X�^���X�擾�G���[���b�Z�[�W�擾
   * @param instanceName �C���X�^���X��
   * @return OAException �C���X�^���X�擾�G���[���b�Z�[�W
   *****************************************************************************
   */
  public static OAException createInstanceLostError(
    String instanceName
  )
  {
    return
      createErrorMessage(
        XxcsoConstants.APP_XXCSO1_00120,
        XxcsoConstants.TOKEN_INSTANCE_NAME,
        instanceName
      );
  }

  /*****************************************************************************
   * �g�����U�N�V�������b�N�G���[���b�Z�[�W�擾
   * @param recordName ���R�[�h��
   * @return OAException �g�����U�N�V�������b�N�G���[���b�Z�[�W
   *****************************************************************************
   */
  public static OAException createTransactionLockError(
    String recordName
  )
  {
    return
      createErrorMessage(
        XxcsoConstants.APP_XXCSO1_00002,
        XxcsoConstants.TOKEN_RECORD,
        recordName
      );
  }

  /*****************************************************************************
   * �g�����U�N�V���������G���[���b�Z�[�W�擾
   * @param recordName ���R�[�h��
   * @return OAException �g�����U�N�V���������G���[���b�Z�[�W
   *****************************************************************************
   */
  public static OAException createTransactionInconsistentError(
    String recordName
  )
  {
    return
      createErrorMessage(
        XxcsoConstants.APP_XXCSO1_00003,
        XxcsoConstants.TOKEN_RECORD,
        recordName
      );
  }

  /*****************************************************************************
   * �s�Ȃ��G���[���b�Z�[�W�擾
   * @param recordName ���R�[�h��
   * @return OAException �s�Ȃ��G���[���b�Z�[�W
   *****************************************************************************
   */
  public static OAException createRecordNotFoundError(
    String recordName
  )
  {
    return
      createErrorMessage(
        XxcsoConstants.APP_XXCSO1_00004,
        XxcsoConstants.TOKEN_RECORD,
        recordName
      );
  }

  /*****************************************************************************
   * �v���t�@�C���E�I�v�V�����l�擾���s�G���[���b�Z�[�W�擾
   * @param profileOptionName �v���t�@�C���E�I�v�V������
   * @return OAException �v���t�@�C���E�I�v�V�����l�擾���s�G���[���b�Z�[�W
   *****************************************************************************
   */
  public static OAException createProfileNotFoundError(
    String profileOptionName
  )
  {
    return
      createErrorMessage(
        XxcsoConstants.APP_XXCSO1_00014,
        XxcsoConstants.TOKEN_PROF_NAME,
        profileOptionName
      );
  }

  /*****************************************************************************
   * �v���t�@�C���E�I�v�V�����l�^�ϊ����s�G���[���b�Z�[�W�擾
   * @param profileOptionName  �v���t�@�C���E�I�v�V������
   * @param profileOptionValue �v���t�@�C���E�I�v�V�����l
   * @return OAException �v���t�@�C���E�I�v�V�����l�^�ϊ����s�G���[���b�Z�[�W
   *****************************************************************************
   */
  public static OAException createProfileOptionValueError(
    String profileOptionName,
    String profileOptionValue
  )
  {
    return
      createErrorMessage(
        XxcsoConstants.APP_XXCSO1_00121,
        XxcsoConstants.TOKEN_PROF_NAME,
        profileOptionName,
        XxcsoConstants.TOKEN_PROF_VALUE,
        profileOptionValue
      );
  }

  /*****************************************************************************
   * SQL�G���[���b�Z�[�W�쐬
   * @param ex  SQLException
   * @param actionValue �v���t�@�C���E�I�v�V�����l
   * @return OAException SQL�G���[���b�Z�[�W
   *****************************************************************************
   */
  public static OAException createSqlErrorMessage(
    SQLException ex,
    String actionValue
  )
  {
    return
      createErrorMessage(
        XxcsoConstants.APP_XXCSO1_00236,
        XxcsoConstants.TOKEN_ACTION,
        actionValue,
        XxcsoConstants.TOKEN_ERRMSG,
        ex.getMessage()
      );
  }

  /*****************************************************************************
   * CSV�쐬���G���[���b�Z�[�W�쐬
   * @param ex  UnsupportedEncodingException
   * @return OAException CSV�쐬���G���[���b�Z�[�W
   *****************************************************************************
   */
  public static OAException createCsvErrorMessage(
    UnsupportedEncodingException uae
  )
  {
    return
      createErrorMessage(
        XxcsoConstants.APP_XXCSO1_00236,
        XxcsoConstants.TOKEN_ACTION,
        XxcsoConstants.TOKEN_VALUE_CSV_CREATE,
        XxcsoConstants.TOKEN_ERRMSG,
        uae.getMessage()
      );
  }

  /*****************************************************************************
   * ������n�G���[���b�Z�[�W�쐬
   * @param actionName   �A�N�V������
   * @param errorMessage ������n�G���[���b�Z�[�W
   * @return OAException ������n�G���[���b�Z�[�W
   *****************************************************************************
   */
  public static OAException createAssociateErrorMessage(
    String actionName,
    String errorMessage
  )
  {
    return
      createErrorMessage(
        XxcsoConstants.APP_XXCSO1_00042,
        XxcsoConstants.TOKEN_ACTION,
        actionName,
        XxcsoConstants.TOKEN_ERRMSG,
        errorMessage
      );
  }

  /*****************************************************************************
   * �ُ�n�G���[���b�Z�[�W�쐬
   * @param actionName   �A�N�V������
   * @param errorMessage �ُ�n�G���[���b�Z�[�W
   * @return OAException �ُ�n�G���[���b�Z�[�W
   *****************************************************************************
   */
  public static OAException createCriticalErrorMessage(
    String actionName,
    String errorMessage
  )
  {
    return
      createErrorMessage(
        XxcsoConstants.APP_XXCSO1_00236,
        XxcsoConstants.TOKEN_ACTION,
        actionName,
        XxcsoConstants.TOKEN_ERRMSG,
        errorMessage
      );
  }

  /*****************************************************************************
   * �X�V�f�[�^�Ȃ��x�����b�Z�[�W�쐬
   * @return OAException �X�V�f�[�^�Ȃ��x���G���[���b�Z�[�W
   *****************************************************************************
   */
  public static OAException createNotChangedMessage(
  )
  {
    return createWarningMessage(XxcsoConstants.APP_XXCSO1_00336);
  }

  /*****************************************************************************
   * �ő�o�^�����G���[���b�Z�[�W�쐬
   * @param objectName   �I�u�W�F�N�g��
   * @param maxSize      �ő�o�^����
   * @return OAException �ُ�n�G���[���b�Z�[�W
   *****************************************************************************
   */
  public static OAException createMaxRowException(
    String objectName,
    String maxSize
  )
  {
    return
      createErrorMessage(
        XxcsoConstants.APP_XXCSO1_00010,
        XxcsoConstants.TOKEN_OBJECT,
        objectName,
        XxcsoConstants.TOKEN_MAX_SIZE,
        maxSize
      );
  }

  /*****************************************************************************
   * �폜�m�F���b�Z�[�W�쐬
   * @param columnName   �J������
   * @param values       �l
   * @return OAException �m�F���b�Z�[�W
   *****************************************************************************
   */
  public static OAException createDeleteWarningMessage(
    String columnName,
    String values
  )
  {
    return
      createWarningMessage(
        XxcsoConstants.APP_XXCSO1_00460,
        XxcsoConstants.TOKEN_COLUMN,
        columnName,
        XxcsoConstants.TOKEN_VALUES,
        values
      );
  }

  /*****************************************************************************
   * ����I�����b�Z�[�W�쐬
   * @param record       �Ώۃ��R�[�h
   * @param action       ���s��
   * @return OAException ����I�����b�Z�[�W
   *****************************************************************************
   */
  public static OAException createCompleteMessage(
    String record,
    String action
  )
  {
    return
      createConfirmMessage(
        XxcsoConstants.APP_XXCSO1_00001,
        XxcsoConstants.TOKEN_RECORD,
        record,
        XxcsoConstants.TOKEN_ACTION,
        action
      );
  }

  /*****************************************************************************
   * ���b�Z�[�W���쐬���܂��B
   * @param applicationShortName �A�v���P�[�V�����Z�k��
   * @param messageType ���b�Z�[�W�^�C�v
   * @param messageName ���b�Z�[�W��
   * @param tokenName1  �g�[�N���P��
   * @param tokenValue1 �g�[�N���P�l
   * @param tokenName2  �g�[�N���Q��
   * @param tokenValue2 �g�[�N���Q�l
   * @param tokenName3  �g�[�N���R��
   * @param tokenValue3 �g�[�N���R�l
   * @return OAException �G���[���b�Z�[�W
   *****************************************************************************
   */
  public static OAException createMessage(
    String applicationShortName,
    byte messageType,
    String messageName,
    String tokenName1,
    String tokenValue1,
    String tokenName2,
    String tokenValue2,
    String tokenName3,
    String tokenValue3
  )
  {
    OAException msg = null;
    
    if ( tokenName1 == null && tokenName2 == null && tokenName3 == null)
    {
      msg = new OAException(
        applicationShortName,
        messageName,
        null,
        messageType,
        null
      );
    }
    if ( tokenName1 != null && tokenName2 == null && tokenName3 == null)
    {
      MessageToken[] token =
      {
        new MessageToken(tokenName1, tokenValue1)
      };
      msg = new OAException(
        applicationShortName,
        messageName,
        token,
        messageType,
        null
      );
    }
    if ( tokenName1 != null && tokenName2 != null && tokenName3 == null)
    {
      MessageToken[] token =
      {
        new MessageToken(tokenName1, tokenValue1),
        new MessageToken(tokenName2, tokenValue2)
      };
      msg = new OAException(
        applicationShortName,
        messageName,
        token,
        messageType,
        null
      );
    }
    if ( tokenName1 != null && tokenName2 != null && tokenName3 != null)
    {
      MessageToken[] token =
      {
        new MessageToken(tokenName1, tokenValue1),
        new MessageToken(tokenName2, tokenValue2),
        new MessageToken(tokenName3, tokenValue3)
      };
      msg = new OAException(
        applicationShortName,
        messageName,
        token,
        messageType,
        null
      );
    }
    return msg;
  }

// Ver.1.1 Add Start
  /*****************************************************************************
   * ���b�Z�[�W���쐬���܂��B
   * @param applicationShortName �A�v���P�[�V�����Z�k��
   * @param messageType ���b�Z�[�W�^�C�v
   * @param messageName ���b�Z�[�W��
   * @param tokenName1  �g�[�N���P��
   * @param tokenValue1 �g�[�N���P�l
   * @param tokenName2  �g�[�N���Q��
   * @param tokenValue2 �g�[�N���Q�l
   * @param tokenName3  �g�[�N���R��
   * @param tokenValue3 �g�[�N���R�l
   * @param tokenName4  �g�[�N���S��
   * @param tokenValue4 �g�[�N���S�l
   * @param tokenName5  �g�[�N���T��
   * @param tokenValue5 �g�[�N���T�l
   * @param tokenName6  �g�[�N���U��
   * @param tokenValue6 �g�[�N���U�l
   * @return OAException �G���[���b�Z�[�W
   *****************************************************************************
   */
  public static OAException createMessage(
    String applicationShortName,
    byte messageType,
    String messageName,
    String tokenName1,
    String tokenValue1,
    String tokenName2,
    String tokenValue2,
    String tokenName3,
    String tokenValue3,
    String tokenName4,
    String tokenValue4,
    String tokenName5,
    String tokenValue5,
    String tokenName6,
    String tokenValue6
  )
  {
    OAException msg = null;
    
    if ( tokenName1 != null && tokenName2 != null && tokenName3 != null && tokenName4 != null && tokenName5 != null && tokenName6 != null)
    {
      MessageToken[] token =
      {
        new MessageToken(tokenName1, tokenValue1),
        new MessageToken(tokenName2, tokenValue2),
        new MessageToken(tokenName3, tokenValue3),
        new MessageToken(tokenName4, tokenValue4),
        new MessageToken(tokenName5, tokenValue5),
        new MessageToken(tokenName6, tokenValue6)
      };
      msg = new OAException(
        applicationShortName,
        messageName,
        token,
        messageType,
        null
      );
    }
    return msg;
  }
// Ver.1.1 Add End
// Ver.1.2 Add Start
  /*****************************************************************************
   * ���b�Z�[�W���쐬���܂��B
   * @param applicationShortName �A�v���P�[�V�����Z�k��
   * @param messageType ���b�Z�[�W�^�C�v
   * @param messageName ���b�Z�[�W��
   * @param tokenName1  �g�[�N���P��
   * @param tokenValue1 �g�[�N���P�l
   * @param tokenName2  �g�[�N���Q��
   * @param tokenValue2 �g�[�N���Q�l
   * @param tokenName3  �g�[�N���R��
   * @param tokenValue3 �g�[�N���R�l
   * @param tokenName4  �g�[�N���S��
   * @param tokenValue4 �g�[�N���S�l
   * @param tokenName5  �g�[�N���T��
   * @param tokenValue5 �g�[�N���T�l
   * @param tokenName6  �g�[�N���U��
   * @param tokenValue6 �g�[�N���U�l
   * @param tokenName7  �g�[�N���V��
   * @param tokenValue7 �g�[�N���V�l
   * @return OAException �G���[���b�Z�[�W
   *****************************************************************************
   */
  public static OAException createMessage(
    String applicationShortName,
    byte messageType,
    String messageName,
    String tokenName1,
    String tokenValue1,
    String tokenName2,
    String tokenValue2,
    String tokenName3,
    String tokenValue3,
    String tokenName4,
    String tokenValue4,
    String tokenName5,
    String tokenValue5,
    String tokenName6,
    String tokenValue6,
    String tokenName7,
    String tokenValue7
  )
  {
    OAException msg = null;
    
    if ( tokenName1 != null && tokenName2 != null && tokenName3 != null && tokenName4 != null && tokenName5 != null && tokenName6 != null && tokenName7 != null )
    {
      MessageToken[] token =
      {
        new MessageToken(tokenName1, tokenValue1),
        new MessageToken(tokenName2, tokenValue2),
        new MessageToken(tokenName3, tokenValue3),
        new MessageToken(tokenName4, tokenValue4),
        new MessageToken(tokenName5, tokenValue5),
        new MessageToken(tokenName6, tokenValue6),
        new MessageToken(tokenName7, tokenValue7)
      };
      msg = new OAException(
        applicationShortName,
        messageName,
        token,
        messageType,
        null
      );
    }
    return msg;
  }
// Ver.1.2 Add End
}