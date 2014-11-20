/*============================================================================
* ファイル名 : XxinvMovementResultsVOImpl
* 概要説明   : 入出庫実績要約:検索ビューオブジェクト
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-12 1.0  大橋孝郎     新規作成
*============================================================================
*/
package itoen.oracle.apps.xxinv.xxinv510001j.server;
import com.sun.java.util.collections.HashMap;
import java.util.ArrayList;

import oracle.apps.fnd.framework.server.OAViewObjectImpl;

import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxinv.util.XxinvConstants;

/***************************************************************************
 * 検索ビューオブジェクトです。
 * @author  ORACLE 大橋 孝郎
 * @version 1.0
 ***************************************************************************
 */
public class XxinvMovementResultsVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxinvMovementResultsVOImpl()
  {
  }

  /*****************************************************************************
   * VOの初期化を行います。
   * @param searchParams 検索パラメータ用HashMap
   ****************************************************************************/
   public void initQuery(
    HashMap searchParams         // 検索キーパラメータ
   )
   {
     StringBuffer whereClause = new StringBuffer(1000);  // WHERE句作成用オブジェクト
     ArrayList parameters = new ArrayList();             // バインド変数設定値
     int bindCount = 0;

     // 初期化
     setWhereClauseParams(null);

     // 検索条件取得
     String movNum              = (String)searchParams.get("movNum");              // 移動番号
     String movType             = (String)searchParams.get("movType");             // 移動タイプ
     String status              = (String)searchParams.get("status");              // ステータス
     String shippedLocatId      = (String)searchParams.get("shippedLocatId");      // 出庫元
     String shipToLocatId       = (String)searchParams.get("shipToLocatId");       // 入庫先
     String shipDateFrom        = (String)searchParams.get("shipDateFrom");        // 出庫日(開始)
     String shipDateTo          = (String)searchParams.get("shipDateTo");          // 出庫日(終了)
     String arrivalDateFrom     = (String)searchParams.get("arrivalDateFrom");     // 着日(開始)
     String arrivalDateTo       = (String)searchParams.get("arrivalDateTo");       // 着日(終了)
     String instructionPostCode = (String)searchParams.get("instructionPostCode"); // 移動指示部署
     String deliveryNo          = (String)searchParams.get("deliveryNo");          // 配送No
     String peopleCode          = (String)searchParams.get("peopleCode");          // 従業員区分
     String actualFlag          = (String)searchParams.get("actualFlag");          // 実績データ区分
     String productFlag         = (String)searchParams.get("productFlag");         // 製品識別区分

     // *************************** //
    // *        条件作成         * //
    // *************************** //

    //入力パラメータの製品識別区分が「1」(製品)の場合
    if ("1".equals(productFlag))
    {
      // 条件追加1件目以降の場合
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND product_flg = '1'");

      // 条件追加1件目の場合
      } else
      {
        whereClause.append(" product_flg = '1'");
      }
    //入力パラメータの製品識別区分が「2」(製品以外)の場合
    } else if ("2".equals(productFlag))
    {
      // 条件追加1件目以降の場合
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND product_flg = '2'");

      // 条件追加1件目の場合
      } else
      {
        whereClause.append(" product_flg = '2'");
      }
    }

    //移動番号が入力されていた場合
    if (!XxcmnUtility.isBlankOrNull(movNum))
    {
     // 条件追加1件目以降の場合
     if (whereClause.length() != 0)
     {
       whereClause.append(" AND mov_num = :" + bindCount);

     // 条件追加1件目の場合
     } else
     {
       whereClause.append(" mov_num = :" + bindCount);
     }
     //バインド変数をカウント
     bindCount = bindCount + 1;
     //検索値をセット
     parameters.add(movNum);
    }

    //移動タイプが入力されていた場合
    if (!XxcmnUtility.isBlankOrNull(movType))
    {
      // 条件追加1件目以降の場合
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND mov_type = :" + bindCount);

      // 条件追加1件目の場合
      } else
      {
        whereClause.append(" mov_type = :" + bindCount);
      }
      //バインド変数をカウント
      bindCount = bindCount + 1;
      //検索値をセット
      parameters.add(movType);
    }

    //ステータスが入力されていた場合
    if (!XxcmnUtility.isBlankOrNull(status))
    {
      // 条件追加1件目以降の場合
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND status = :" + bindCount);

      // 条件追加1件目の場合
      } else
      {
        whereClause.append(" status = :" + bindCount);
      }
      //バインド変数をカウント
      bindCount = bindCount + 1;
      //検索値をセット
      parameters.add(status);
    }

    //出庫元が入力されていた場合
    if (!XxcmnUtility.isBlankOrNull(shippedLocatId))
    {
      // 従業員区分が1:内部ユーザの場合
      // 又は従業員区分が2:外部ユーザかつ入力パラメータの実績データ区分が1(出庫)の場合
     if (XxinvConstants.PEOPLE_CODE_I.equals(peopleCode) || ((XxinvConstants.PEOPLE_CODE_O.equals(peopleCode)) && ("1".equals(actualFlag))))
     {
       
       // 条件追加1件目以降の場合
       if (whereClause.length() != 0)
       {
         whereClause.append(" AND shipped_locat_id = :" + bindCount);

       // 条件追加1件目の場合
       } else
       {
         whereClause.append(" shipped_locat_id = :" + bindCount);
       }
       //バインド変数をカウント
       bindCount = bindCount + 1;
       //検索値をセット
       parameters.add(shippedLocatId);
      }
    }

    //入庫先が入力されていた場合
    if (!XxcmnUtility.isBlankOrNull(shipToLocatId))
    {
      // 従業員区分が1:内部ユーザの場合
      // 又は従業員区分が2:外部ユーザかつ入力パラメータの実績データ区分が2(入庫)の場合
      if (XxinvConstants.PEOPLE_CODE_I.equals(peopleCode) 
        || ((XxinvConstants.PEOPLE_CODE_O.equals(peopleCode)) 
        && ("2".equals(actualFlag))))
      {
      
        // 条件追加1件目以降の場合
        if (whereClause.length() != 0)
        {
          whereClause.append(" AND ship_to_locat_id = :" + bindCount);

        // 条件追加1件目の場合
        } else
        {
          whereClause.append(" ship_to_locat_id = :" + bindCount);
        }
        //バインド変数をカウント
        bindCount = bindCount + 1;
        //検索値をセット
        parameters.add(shipToLocatId);
      }
    }

    //出庫日FROMが入力されていた場合
    if (!XxcmnUtility.isBlankOrNull(shipDateFrom))
    {
      // 条件追加1件目以降の場合
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND schedule_ship_date >= :" + bindCount);

      // 条件追加1件目の場合
      } else
      {
        whereClause.append(" schedule_ship_date >= :" + bindCount);
      }
      //バインド変数をカウント
      bindCount = bindCount + 1;
      //検索値をセット
      parameters.add(shipDateFrom);
    }

    //出庫日TOが入力されていた場合
    if (!XxcmnUtility.isBlankOrNull(shipDateTo))
    {
      // 条件追加1件目以降の場合
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND schedule_ship_date <= :" + bindCount);

      // 条件追加1件目の場合
      } else
      {
        whereClause.append(" schedule_ship_date <= :" + bindCount);
      }
      //バインド変数をカウント
      bindCount = bindCount + 1;
      //検索値をセット
      parameters.add(shipDateTo);
    }

    //着日FROMが入力されていた場合
    if (!XxcmnUtility.isBlankOrNull(arrivalDateFrom))
    {
      // 条件追加1件目以降の場合
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND schedule_arrival_date >= :" + bindCount);

      // 条件追加1件目の場合
      } else
      {
        whereClause.append(" schedule_arrival_date >= :" + bindCount);
      }
      //バインド変数をカウント
      bindCount = bindCount + 1;
      //検索値をセット
      parameters.add(arrivalDateFrom);
    }

    //着日TOが入力されていた場合
    if (!XxcmnUtility.isBlankOrNull(arrivalDateTo))
    {
      // 条件追加1件目以降の場合
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND schedule_arrival_date <= :" + bindCount);

      // 条件追加1件目の場合
      } else
      {
        whereClause.append(" schedule_arrival_date <= :" + bindCount);
      }
      //バインド変数をカウント
      bindCount = bindCount + 1;
      //検索値をセット
      parameters.add(arrivalDateTo);
    }

    //移動指示部署が入力されていた場合
    if (!XxcmnUtility.isBlankOrNull(instructionPostCode))
    {
      // 条件追加1件目以降の場合
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND instruction_post_code = :" + bindCount);

      // 条件追加1件目の場合
      } else
      {
        whereClause.append(" instruction_post_code = :" + bindCount);
      }
      //バインド変数をカウント
      bindCount = bindCount + 1;
      //検索値をセット
      parameters.add(instructionPostCode);
    }

    //配送Noが入力されていた場合
    if (!XxcmnUtility.isBlankOrNull(deliveryNo))
    {
      // 条件追加1件目以降の場合
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND delivery_no = :" + bindCount);

      // 条件追加1件目の場合
      } else
      {
        whereClause.append(" delivery_no = :" + bindCount);
      }
      //バインド変数をカウント
      bindCount = bindCount + 1;
      //検索値をセット
      parameters.add(deliveryNo);
    }


    // 検索条件をVOにセット
    setWhereClause(whereClause.toString());

    // バインド値が設定されていた場合
    if (bindCount > 0)
    {
      // 検索値配列を取得
      Object[] params = new Object[bindCount];
      params = parameters.toArray();
      // WHERE句のバインド変数に検索値をセット
      setWhereClauseParams(params);

    }
    executeQuery();
   }
}